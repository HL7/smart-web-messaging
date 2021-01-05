{::comment}

  COMMON TERMS, which will reveal a hover-text definition in the IG when viewed.

{:/comment}
*[API]: Application Programming Interface
*[CDS]: Clinical Decision Support
*[CPOE]: Computerized Physician Order Entry
*[CRUD]: Copy Read Update Delete
*[EHR]: Electronic Health Record
*[EHRs]: Electronic Health Record
*[OAuth]: An open standard for access delegation, commonly used as a way for Internet users to grant websites or applications access to their information on other websites but without giving them the passwords.
*[UX]: User Experience

{::comment}

  LINKS, which enable the markdown to simply reference [link name] for short.

{:/comment}
[Activity Catalog]: ./activity-catalog.html
[Alternatives Considered]: ./alternatives-considered.html
[`Bundle.entry.response`]: http://hl7.org/fhir/bundle-definitions.html#Bundle.entry.response.location
[CDS Hooks Action]: https://cds-hooks.hl7.org/1.0/#action
[FHIR OperationOutcome]: https://www.hl7.org/fhir/operationoutcome.html
[FHIRCast]: http://fhircast.org
[HTML5's Web Messaging]: https://html.spec.whatwg.org/multipage/web-messaging.html
[`MessageEvent`]: https://html.spec.whatwg.org/multipage/comms.html#messageevent
[OAuth]: https://oauth.net/
[OAuth 2.0]: https://oauth.net/2/
[OAuth scopes]: https://oauth.net/2/scope/
[RESTful FHIR API]: http://hl7.org/fhir/http.html
[RFC2119]: https://tools.ietf.org/html/rfc2119
[SMART applications]: http://hl7.org/fhir/smart-app-launch/index.html
[`window.postMessage`]: https://html.spec.whatwg.org/multipage/web-messaging.html#posting-messages

SMART Web Messaging enables tight UI integration between EHRs and embedded SMART apps via [HTML5's Web Messaging].  SMART Web Messaging allows applications to push unsigned orders, note snippets, risk scores, or UI suggestions directly to the clinician's EHR session.  Built on the browser's javascript [`window.postMessage`] function, SMART Web Messaging is a simple, native API for health apps embedded within the user's workflow.

#### Conformance Language
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to be interpreted as described in [RFC2119].

### Why
Clinical workflow systems (such as EHRs) may be able to launch [SMART applications] in a few different ways: automatically at specific points in the workflow, by user interaction in the UI, or in response to a suggestion from a [CDS Hooks Service](https://cds-hooks.hl7.org/1.0/#cds-hooks-anatomy).  Once launched, web applications are often embedded within an iframe of the main UI.  In this model, the new application appears in close proximity to a patient's chart and can work with the EHR via [RESTful FHIR API].  These RESTful APIs are great for [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) operations on a logical FHIR Server endpoint, but they don't enable tight workflow integration or access to draft FHIR resources that may only exist in memory on the EHR client.

For these embedded apps, there are some key use cases that SMART and CDS Hooks don't address today:

* Communicating a decision made by the clinician within the SMART app, such as:
  * placing an order
  * annotating a procedure with an appropriateness score or a radiation count
  * transmitting a textual note snippet
  * suggesting a diagnosis or a condition to the patient's chart
* Interrogating the orders scratchpad / shopping cart, currently only known within the ordering provider's [CPOE](https://en.wikipedia.org/wiki/Computerized_physician_order_entry) session.
* Allowing an app to communicate [UX](https://en.wikipedia.org/wiki/User_experience)-relevant results back to the EHR, for example, automatic navigation to a native EHR activity, or sending an "I'm done" signal.

Additionally, SMART Web Messaging enables other interesting capabilities.  For example:
* Saving app-specific session or state identifiers to the EHR for later retrieval (continuing sessions).
* Interacting with the EHR's FHIR server through this messaging channel (enabling applications that cannot access the FHIR server directly, e.g. those hosted on the internet).

### SMART Web Messaging
SMART Web Messaging builds on [HTML5's Web Messaging] specification, which
allows web pages to communicate across domains.  In JavaScript, calls to
[`window.postMessage`] pass [`MessageEvent`] objects between windows.

A [`window.postMessage`]-based messaging approach allows flexible,
standards-based integration that works across windows, frames and domains, and
should be readily supportable in browser controls for any HTML5-capable browser-based EHR.

#### Request Parameters
For the purposes of SMART Web Messaging, a [`window.postMessage`] call from an app to an EHR client SHALL contain a JSON message object with the following properties:

| Property          | Optionality  | Type   | Description |
| ----------------- | ------------ | ------ | ----------- |
| `messagingHandle` | REQUIRED     | string | The content of the `smart_web_messaging_handle` property of the [OAuth] access token response JSON payload.  ([Details below.](#authorization-with-smart-scopes)). |
| `messageId`       | REQUIRED     | ID     | A unique ID for this message generated by the application. |
| `messageType`     | REQUIRED     | string | The type of this message (e.g., `ui.done`, `scratchpad.update`). |
| `payload`         | REQUIRED     | object | The message content as specified by the `messageType`.  See below. |
{:.grid}

This message object MUST be passed to [`window.postMessage`] using a valid `targetOrigin` parameter.  The EHR MUST provide the `smart_messaging_origin` property to the app in the initial SMART launch context alongside the `access_token`.  Applications SHOULD NOT use `"*"` for the `targetOrigin` parameter for [security reasons](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage#Security_concerns).

{::comment}

  TODO: include an example of using the SMART app launch client here, and extracting the smart_messaging_origin from the launch context.  Link to the javascript FHIR client?
  See: https://github.com/HL7/smart-web-messaging/issues/18

{:/comment}

#### Example Request
An example call from an app to the EHR client is presented below.

```js
// When a SMART app is launched embedded in an iframe, window.parent and window.self
// are different objects, with window.parent being the recipient of MessageEvents.
// When a SMART app is launched standalone, window.parent and window.self are the same.
// In that case, window.opener will be the object receiving MessageEvents.
const targetWindow = window.parent !== window.self ? window.parent : window.opener;

// Read the smart_messaging_origin property from the launch context (alongside the access_token).
// This value provides the app with the EHR client's expected target origin.
const targetOrigin = "<smart_messaging_origin> from SMART launch context";

// The smart_web_messaging_handle is a launch context property also alongside the access_token.
const message = {
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
  "messageId":       "<some new uid>",
  "messageType":     "scratchpad.create",
  "payload":         {}  // See below.
};

targetWindow.postMessage(message, targetOrigin);
```

In the EHR, the message is received and is handled as shown below.

```js
window.addEventListener("message", function(event) {
  if (event.origin !== "<the app's expected origin>") {
    return;  // Ignore unknown origins.
  }

  //
  // TODO: Handle the message here by using the contents of event.data.
  //

  // Send a response back to the app.
  const response = {
    ...  // See below for more details on the response properties.
  };
  event.source.postMessage(response, event.origin);
});
```

#### Response Properties
The EHR SHALL send a response message with the following properties:

| Property              | Optionality  | Type   | Description |
| --------------------- | ------------ | ------ | ----------- |
| `messageId`           | REQUIRED     | ID     | A unique ID for this message generated by the application. |
| `responseToMessageId` | REQUIRED  | ID     | The `messageId` of the received message that this message is in response to.|
| `payload`             | REQUIRED     | object | The message content as specified by the `messageType` of the request message.  See [below](#response-payload). |
{:.grid}

In addition to sending Web Messaging Responses to the app, the EHR MAY also send "unsolicited" requests to the app, omitting  a `responseToMessageId` property. The semantics of such requests are are implementation-specific.
#### Response Payload
The response message `payload` properties will vary based on the request `messageType`.  See message types below for details.

#### Response Target Origin
It is assumed that the EHR already knows the proper `targetOrigin` to use in its
call to [`window.postMessage`] because it has demonstrated that it can SMART
launch the app at a known SMART launch URL.  The SMART launch URL SHALL be
prefixed with the proper value to use for the app `targetOrigin`, and the launch
URL SHALL NOT redirect users to a different origin after launch.

#### Detailed Example Response
In a more detailed example response, the EHR may send one return message like:

```js
window.addEventListener("message", function(event) {
  if (event.origin != "<the app's expected origin>") {
    return;  // Ignore unknown origins.
  }

  //
  // TODO: Handle the message here, using the contents of event.data.
  //

  // Send a response back to the app.
  const response = {
    "responseToMessageId": event.data.messageId,
    "messageId": "<some new uid>",
    // The response payload is modeled after Bundle.entry.response.
    // See: https://www.hl7.org/fhir/bundle-definitions.html#Bundle.entry.response
    "payload": {
      "location": "Example/123",
      // For errors encountered handling the request, the EHR can add an
      // OperationOutcome to contain additional information.
      // See: https://www.hl7.org/fhir/operationoutcome.html
      "outcome": {},
      "status": "200 OK",
    }
  };
  event.source.postMessage(response, event.origin);
});
```

Then, back in the app, the message response is received and handled as shown in
this example.

```js
window.addEventListener("message", function(event) {
  if (event.origin != "<the EHR's origin>") {
    return;  // Ignore unknown origins.
  }

  const requestId = event.data.responseToMessageId;

  if (event.data.payload.status == "200 OK") {
    // Success!
  } else {
    // Error handling.
  }
});
```

#### Workflow Summary
This mechanism enables a full request/response pattern.

##### Unsolicited Responses
Applications SHOULD be prepared to see, at most, one incoming message with a
given `responseToMessageId`.  If multiple response messages (e.g., streams) are
needed, this can be accomplished by having the server send "unsolicited"
messages, i.e., messages with no `responseToMessageId`, after a client's initial
request.

### Influence the EHR UI: `ui.*` message type
An embedded SMART app may improve the clinician's user experience by attempting
to close itself when appropriate, or by requesting the EHR automatically
navigate the user to an appropriate 'next' activity.  Messages that affect the
EHR UI will have a `messageType` that matches the pattern `ui.*`.

The `ui` category includes messages: `ui.done` and `ui.launchActivity`.

The `ui.done` message type signals the EHR to close the activity hosting the
SMART app, and optionally navigates the user to a 'next' activity.

The `ui.launchActivity` message type signals the EHR to navigate the user to another
activity without closing the SMART app.

#### Request payload for `ui.done` and `ui.launchActivity`

| Property             | Optionality | Type   | Description |
| -------------------- | ----------- | ------ | ----------- |
| `activityType`       | CONDITIONAL | string | REQUIRED for `ui.launchActivity`, optional for `ui.done`. Navigation hint; see description below. |
| `activityParameters` | CONDITIONAL | object | REQUIRED for `ui.launchActivity`, optional for `ui.done`. Navigation hint; see description below. |
{:.grid}

#### Response payload for `ui.done` and `ui.launchActivity`

| Property  | Optionality | Type    | Description |
| --------- | ----------- | ------- | ----------- |
| `success` | REQUIRED    | boolean | `true` if the request has been accepted; `false` if it has been rejected. |
| `details` | OPTIONAL    | string  | A human readable explanation of the outcome. |
{:.grid}

The `activityType` property conveys an activity type drawn from the SMART Web
Messaging [Activity Catalog]. In general, these activities follow the same
naming conventions as entries in the CDS Hooks catalog (`noun-verb`), and will
align with CDS Hooks catalog entries where feasible. The `activityType` property
conveys a navigation target such as `problem-add` or `order-sign`, indicating
where EHR should go to after the ui message has been handled. An activity MAY
specify additional parameters that can be included in the call as additional
properties.

The `activityParameters` property conveys parameters specific to an activity
type. See the SMART Web Messaging [Activity Catalog] for details.

*Note:* A SMART app launched in the context of CDS Hooks should generally not
need to specify an `activityType` or `activityParameters` with the `ui.done`
message, because the EHR tracks the context in which the app was launched (e.g.,
order entry) and can navigate to an appropriate follow-up screen based on this
context.

An example of a `ui.done` message from an app to the EHR is shown below:

```js
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messageType": "ui.done",
  "payload": {
    "activityType": "problem-add",
    "activityParameters": {
      // Each ui activity defines its optional and required params.  See the
      // Activity Catalog for more details.
      "problem": {
        "resourceType": "Condition",
        "patient": "123",
      }
    }
  }
}, targetOrigin);
```

Similarly, the SMART app can use the `ui.launchActivity` message type to request
navigation to a different activity *without* closing the app:

```js
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messageType": "ui.launchActivity",
  "payload": {
    "activityType": "problem-add",
    "activityParameters": {
      // Each ui activity defines its optional and required params.  See the
      // Activity Catalog for more details.
      "problem": {
        "resourceType": "Condition",
        "patient": "123",
      }
    }
  }
}, targetOrigin);
```

The EHR SHALL respond to all `ui` message types with a payload that includes a
boolean `success` parameter and an optional `details` string:

```js
clientAppWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<uid from the client's request>",
  "payload": {
    "success": true,
    "details": "string explanation for user (optional)"
  }
}, clientAppOrigin);
```

### EHR Scratchpad Interactions: `scratchpad.*` message type
While interacting with an embedded SMART app, a clinician may make decisions
that should be implemented in the EHR with minimal clicks.  SMART Web Messaging
exposes an API to the clinician's scratchpad within the EHR, which may contain
FHIR resources unavailable on the [RESTful FHIR API].

For example, the proposed CDS Hooks decision workflow can be implemented through
SMART Web Messaging.

All messages affecting the scratchpad have a `messageType` matching the pattern
`scratchpad.*`.

SMART Web Messaging is designed to be compatible with CDS Hooks, and to
implement the CDS Hooks decisions flow.  For any [CDS Hooks Action] array, you
can create a list of SMART Web Messaging API calls:

* [CDS Hooks Action] `type` is used to populate the response `messageType`
  * `create`→ `scratchpad.create`
  * `update`→ `scratchpad.update`
  * `delete`→ `scratchpad.delete`
* [CDS Hooks Action] `resource`: used to populate the `payload.resource`

#### Request payload for `scratchpad.*`

| Property              | Optionality  | Type   | Description |
| --------------------- | ------------ | ------ | ----------- |
| `resource`            | CONDITIONAL  | object | REQUIRED for `scratchpad.create` and `scratchpad.update`. Prohibited for `scratchpad.delete`.  Conveys resource content as per CDS Hooks Action's `payload.resource`. |
| `location`            | CONDITIONAL  | string | REQUIRED for `scratchpad.delete` and `scratchpad.update`.  Prohibited for `scratchpad.create`. |
{:.grid}

#### Response payload for `scratchpad.*`

The EHR responds to all `scratchpad` message types with a payload that matches
FHIR's [`Bundle.entry.response`] data model. The table below includes only
the most commonly used fields; see the FHIR specification for full details.

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `status`              | REQUIRED    | string | An HTTP response code (i.e. "200 OK"). |
| `location`            | CONDITIONAL | string | REQUIRED if a new resource has been added to the scratchapd. Conveys a relative resource URL for the new resource. |
| `outcome`             | OPTIONAL    | object | [FHIR OperationOutcome] with details if something has gone wrong. |
{:.grid}

The following example adds a new `ServiceRequest` to the EHR's scratchpad:

```js
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messageType": "scratchpad.create",
  "payload": {
    "resource": {
      "resourceType": "ServiceRequest",
      "status": "draft",
      // additional details as needed
    }
  }
}, targetOrigin);
```

For example, a proposal to update a draft prescription in the context of a CDS
Hooks request might look like:

```js
// Update to a better, cheaper alternative prescription
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messageType": "scratchpad.update",
  "payload": {
    "resource": {
      "resourceType": "MedicationRequest",
      "id": "123",
      "status": "draft"
      // additional details as needed
    }
  }
}, targetOrigin);
```

As described above, the EHR responds to all `scratchpad` message types with a
payload that matches FHIR's [`Bundle.entry.response`] data model.  For instance,
the response to a `scratchpad.create` that adds a new prescription to the
scratchpad (and assigns id `456` to this draft resource) might look like:

```js
clientAppWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<uid from the client's request>",
  "payload": {
    "status": "200 OK",
    "location": "MedicationRequest/456"
  }
}, clientAppOrigin);
```

To delete `MedicationRequest/456` from the EHR's scratchpad, the client would issue this message:

```js
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messageType": "scratchpad.delete",
  "payload": {
    "location": "MedicationRequest/456"
  }
}, targetOrigin);
```

### Authorization with SMART Scopes
SMART Web Messaging enables capabilities that can be authorized via
[OAuth scopes], within the `messaging/` category.  Authorization is at the level
of message groups (e.g., `messaging/ui`) rather than specific messages (e.g.,
`launchActivity`).  For example, a SMART app that performs dosage adjustments to
in-progress orders might request the following scopes:

* `patient/MedicationRequest.read`: enable access to existing prescribed medications
* `messaging/scratchpad`: enable access to draft orders (including meds) on the EHR scratchpad
* `messaging/ui`: enable access to EHR navigation (e.g., to signal when the app is "done")

At the time of launch, the app receives a `smart_web_messaging_handle` alongside
the [OAuth] `access_token`.  This `smart_web_messaging_handle` is used to
correlate [`window.postMessage`] requests to the authorization context.  We
define this as a distinct parameter from the access token itself because in many
app architectures, the access token will only live server-side, and the
`smart_web_messaging_handle` is explicitly designed to be safely pushed up to
the browser environment.  (It confers limited permissions, and is entirely
focused on the Web Messaging interactions without enabling full REST API
access.)  A server MAY restrict the use of a single `smart_web_messaging_handle`
to requests from a single app window, and SHOULD apply logic to invalidate the
handle when appropriate (e.g., the server might invalidate the handle when the
user session ends).

*Note on security goals: We include a `smart_web_messaging_handle` in the request to ensure that a SMART app launch has been completed prior to any SMART Web Messaging API calls.  Requiring this parameter is part of a defense-in-depth strategoy to mitigate some cross-site-scripting (XSS) attacks.*

#### Scope examples

```text
 Location: https://ehr/authorize?
  response_type=code&
  client_id=app-client-id&
  redirect_uri=https%3A%2F%2Fapp%2Fafter-auth&
  launch=xyz123&
  scope=+launch+patient%2FMedicationRequest.read+messaging%2Fui.launchActivity+openid+profile&
  state=98wrghuwuogerg97&
  aud=https://ehr/fhir
```

Following the [OAuth 2.0] handshake, the authorization server returns the
authorized SMART launch parameters alongside the `access_token`.  Note the
`scope`, `smart_web_messaging_handle`, and `smart_messaging_origin` values:

```json
 {
  "access_token": "i8hweunweunweofiwweoijewiwe",
  "token_type": "bearer",
  "expires_in": 3600,
  "scope": "patient/Observation.read patient/Patient.read messaging/ui.launchActivity",
  "smart_web_messaging_handle": "bws8YCbyBtCYi5mWVgUDRqX8xcjiudCo",
  "smart_messaging_origin": "https://ehr.example.org",
  "state": "98wrghuwuogerg97",
  "patient":  "123",
  "encounter": "456"
}
```

### Limitations
The use of web messaging requires the app to be a web application, which is
either embedded within an iframe or launched in a new tab/window.

SMART Web Messaging is not a context synchronization specification (see
[FHIRCast]).  Rather, it's a collection of functions available to a web app
embedded within an EHR which supports tight workflow integration.

### Alternatives considered
See [Alternatives Considered].

### Open questions for ballot feedback

#### Discovery of server capabilities
In the current proposal, we leave discovery out of band. For example, a client
must consult server documentation to determine which message types a server
supports.  We welcome ballot comments that consider whether we should define an
in-band way to advertise which message types (and possibly which parameters) a
server supports (e.g. via added details in a `.well-known/smart-configuration`).

#### Handshake protocol
In the current proposal, we omit any initial handshake; a client can submit a
Web Messaging request at any point, and can determine whether a connection is
working based on a combination of responses and/or timeout logic.  We welcome
ballot comments that consider the utility of an explicit handshake, taking into
account the fact that a initially working connection (e.g., at handshake time)
can always degrade later.

#### Security considerations
In the current proposal, we provide infrastructure for servers to correlate Web
Messaging requests with a specific SMART App Launch context, through the
`smart_web_messaging_handle`. However we do not require that servers make use of
this property.  We refer commenters to [discussion and rationale here](https://github.com/HL7/smart-web-messaging/pull/4)
and welcome any additional feedback on this point.

#### General FHIR API interactions
In the current proposal, we limit message types to `ui` and `scratchpad` for messages sent from the app to the EHR client.  However, it might be convenient for apps if the SMART Web Messaging standard supported a `fhir` message type, which would signify messages meant to be relayed from the app, through the EHR client to the FHIR server.  We welcome ballot comments that speak to the merits or risks of this capability; based on feedback we will consider introducing  a `fhir.*` message type.

#### Independent maturity models for message types and activities
FHIRCast and CDS Hooks specify their events (or hooks) in separate specifications, using their own maturity models and lifecycles.  Should the SMART Web Messaging adopt similar patterns for its message types and activities?
