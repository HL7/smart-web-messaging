{::comment}

  COMMON TERMS, which will reveal a hover-text definition in the IG when viewed.

{:/comment}
*[API]: Application Programming Interface
*[CDS]: Clinical Decision Support
*[CPOE]: Computerized Physician Order Entry
*[CRUD]: Create Read Update Delete
*[EHR]: Electronic Health Record
*[EHRs]: Electronic Health Records
*[OAuth]: An open standard for access delegation, commonly used as a way for Internet users to grant websites or applications access to their information on other websites but without giving them the passwords.
*[UX]: User Experience

{::comment}

  LINKS, which enable the markdown to simply reference [link name] for short.

{:/comment}
[Activity Catalog]: ./activity-catalog.html
[Alternatives Considered]: ./alternatives-considered.html
[`Bundle.entry.response`]: https://hl7.org/fhir/bundle-definitions.html#Bundle.entry.response.location
[CDS Hooks]: https://cds-hooks.hl7.org/1.0
[CDS Hooks Action]: https://cds-hooks.hl7.org/1.0/#action
[FHIR]: https://hl7.org/fhir/
[FHIR Coding]: https://www.hl7.org/fhir/datatypes.html#Coding
[FHIR OperationOutcome]: https://www.hl7.org/fhir/operationoutcome.html
[FHIRCast]: https://fhircast.org
[HTML5]: https://html.spec.whatwg.org/multipage
[HTML5's Web Messaging]: https://html.spec.whatwg.org/multipage/web-messaging.html
[JSON (RFC8259)]: https://tools.ietf.org/html/rfc8259
[`MessageEvent`]: https://html.spec.whatwg.org/multipage/comms.html#messageevent
[OAuth]: https://oauth.net/
[OAuth 2.0]: https://oauth.net/2/
[OAuth scopes]: https://oauth.net/2/scope/
[RESTful FHIR API]: https://hl7.org/fhir/http.html
[RFC2119]: https://tools.ietf.org/html/rfc2119
[SMART applications]: https://hl7.org/fhir/smart-app-launch/index.html
[`window.postMessage`]: https://html.spec.whatwg.org/multipage/web-messaging.html#posting-messages

SMART Web Messaging enables tight UI integration between EHRs and embedded SMART apps via [HTML5's Web Messaging].

Built on the browser's javascript [`window.postMessage`] function, SMART Web Messaging is a simple, native API for health apps embedded within the user's workflow.  SMART Web Messaging allows applications to push unsigned orders, note snippets, risk scores, UI suggestions etc. directly to the clinician's EHR session.  This allows the EHR to manage the UI behvior for these interactions, such as highlighting the newly created unsigned order, unlike with a CRUD operation on the FHIR REST-ful endpoint which may push an unsigned order, note snippet, risk score etc. but may not become evident in the clinician UI immediately.  This also enables the SMART app to suggest UI changes such as closing the app itself, navigating the clinician to various UI activities in the EHR etc.

#### Conformance Language
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to be interpreted as described in [RFC2119].

#### Underlying Standards

* [FHIR] 
* [CDS Hooks]
* [JSON (RFC8259)]
* [HTML5]

SMART Web Messaging is designed for compatibility with FHIR R4 and above.

### Why
Clinical workflow systems (such as EHRs) may be able to launch [SMART applications] in a few different ways: 
* automatically at specific points in the workflow, 
* in response to a user interaction event in the UI, 
* or in response to a SMART app link from a [CDS Hooks Service](https://cds-hooks.hl7.org/1.0/#cds-hooks-anatomy) (or *other* decision support service).  

Once launched, SMART web applications are often embedded within an iframe in the main UI of the EHR.  In this model, the new application appears in close proximity to a patient's chart and can work with the EHR via [RESTful FHIR API].  These RESTful APIs are great for [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) operations on a logical FHIR Server endpoint. However, being RESTful APIs, they don't enable tight workflow integration. Additionally, access to draft FHIR resources such as unsigned orders may not always be available through the EHR's [RESTful FHIR API].

For these embedded apps, there are therefore some key use cases that the SMART on FHIR model doesn't address today:
* Communicating a decision made by the clinician within the SMART app, such as:
  * placing an unsigned order with visual indication to the clinician that the order was created and requires signing
  * updating an unsigned procedure that the clinician is working on with an appropriateness score or a radiation count
  * transmitting a draft textual note snippet for the clinician to update and finalize in their notes
  * adding a diagnosis or a condition to the patient's chart with UI indication to the clinician
* Interrogating the set of unsigned orders the clinician is actively working on within their [CPOE](https://en.wikipedia.org/wiki/Computerized_physician_order_entry) session. Depending on EHR implementation, these may not be accessible via the EHR's [RESTful FHIR API].
* Allowing an app to communicate [UX](https://en.wikipedia.org/wiki/User_experience)-relevant results back to the EHR.  For example: 
  * automatic navigation to a native EHR activity, 
  * or sending an "I'm done" signal.

Additionally, SMART Web Messaging MAY enable other interesting capabilities in the future.  For example:
* Saving app-specific session or state identifiers to the EHR for later retrieval (continuing sessions).
* Interacting with the EHR's FHIR server through this messaging channel (enabling applications that cannot access the FHIR server directly, e.g. those hosted on the internet).

### Roles
The SMART Web Messaging specification envisions the following roles for actors in this specification. SMART Web Messaging post messages sent from one role to another specify a message type that MUST be prefixed with the role name of the intended recipient.

| Role    | Description |
| ------- | ----------- |
| ui      | The user interface of the EHR that the SMART app interacts with |
| app     | The SMART app using SMART Web Messaging |
| fhir    | An EHR delegate actor that provides a SMART Web Messaging proxy endpoint to the [RESTful FHIR API] |
{:.grid}

#### `ui` role
This is the user interface of the EHR that is hosting the SMART app. It provides the following capabilities for the app.
* The `ui` of the EHR that the SMART Web Messaging app interacts with provides managed access to work in progress resources such as unsigned orders within the EHR that may not otherwise be available through the [RESTful FHIR API].
* The `ui` allows the SMART Web Messaging app to perform user-interface interactions such as closing the app or taking the clinician to another activity.

#### `app` role
This role represents the SMART app itself, that is interacting with the EHR `ui` using SMART Web Messaging. Interactions between multiple SMART apps simultaneously hosted within an EHR `ui` are currently not within the scope of this specification.

#### `fhir` role
This role represents a Web Messaging proxy to the [RESTful FHIR API] that the EHR MAY expose to the `app`. This allows the SMART Web Messaging app to gain client side access to the [RESTful FHIR API] rather than having to make web service calls to the [RESTful FHIR API] directly.

At this point of writing, this role is still only a proposal. We welcome connectathon feedback from implementers on the usefulness and specifics of this role. 


### SMART Web Messaging
SMART Web Messaging builds on [HTML5's Web Messaging] specification, which allows web pages to communicate across domains.  In JavaScript, calls to [`window.postMessage`] pass [`MessageEvent`] objects between windows.

A [`window.postMessage`]-based messaging approach allows flexible, standards-based integration that works across windows, frames and domains, and should be readily supportable in browser controls for any EHR capable of embedding a web application.

Since [`window.postMessage`] only allows for uni-directional communication, a bi-directional communication model is created using two [`window.postMessage`] calls, one constituting a `request` from the requesting role to the recipient role, and a second constituting a `response` from the recipient role to the requesting role. Each individual message is prefixed with the name of the recipient role. All response messages will contain a populated `responseToMessageId` field, which correlates to an initial `messageId` field sent in a request message.  See the following sections for more details.

Requests are currently all initiated by the `app`. There are currently no requests in this specification initiated by a role other than the `app`, but that maay change in the future.

Certain `request` messages such as `ui.done` may not recieve a response.

#### Request Properties
For the purposes of SMART Web Messaging, a [`window.postMessage`] `request` from a caller SHALL contain a JSON message object with the following properties:

| Property          | Optionality  | Type   | Description |
| ----------------- | ------------ | ------ | ----------- |
| `messagingHandle` | REQUIRED     | string | The content of the `smart_web_messaging_handle` property of the [OAuth] access token response JSON payload.  ([Details below.](#authorization-with-smart-scopes)). |
| `messageId`       | REQUIRED     | string | A unique ID for this message generated by the application. |
| `messageType`     | REQUIRED     | string | The type of this message (e.g., `ui.done`, `ui.update`, `ui.handshake`, etc). |
| `payload`         | REQUIRED     | object | The message content as specified by the `messageType`.  See below. |
{:.grid}

##### Handshake
The purpose of the handshake is to allow `app`s to determine, just after launch time, if SMART Web Messaging is enabled in the EHR; and possibly to discover what capabilities the EHR supports within the context of this particular SMART app launch.

The `app` MAY initiate an OPTIONAL handshake message sequence, using the value `ui.handshake` as the value for the `messageType` in the SMART Web Messaging `request` and an empty object for the `payload`.  The EHR, upon receiving the handshake `request` SHOULD respond with an appropriate handshake `response` message.

Extensions MAY be used for handshake `request`s and `response`s, and MAY be used to advertise capabilities.

#### Request Payload
The `request` message `payload` properties will vary based on the request `messageType`.  See message types below for details.

#### Request Target Origin

This message object MUST be passed to [`window.postMessage`] using a valid `targetOrigin` parameter.  The caller MUST provide the `smart_messaging_origin` property to the receiver in the initial SMART launch context alongside the `access_token`.  Callers SHOULD NOT use `"*"` for the `targetOrigin` parameter for [security reasons](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage#Security_concerns).

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
  "messageType":     "ui.handshake",
  "payload":         {}  // See below.
};

targetWindow.postMessage(message, targetOrigin);
```

In the EHR, the message is received and is handled as shown below.

```js
window.addEventListener("message", listener);
function listener(event) {
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
}
```

#### Response Properties
The SMART Web Messaging recipient SHALL send a `response` message with the following properties:

| Property              | Optionality  | Type    | Description |
| --------------------- | ------------ | ------- | ----------- |
| `messageId`           | REQUIRED     | string  | A unique ID for this message generated by the caller. |
| `messageType`         | REQUIRED     | string  | Will be `<requestor-role>.response` where requestor role will currently always be `app`. |
| `responseToMessageId` | REQUIRED     | string  | The `messageId` of the received message that this message is in response to. |
| `status`              | REQUIRED     | string  | Response status can have values `success` or `error`. This value-set may be extended in the future to capture other statuses  |
| `statusDetail`        | OPTIONAL     | coding array  | A FHIR Coding array that captures various warnings, errors etc. that the SMART Web Messaging recipient wishes to convey to the requestor. |
| `payload`             | REQUIRED     | object | The `response` content as specified by the `messageType` of the request message.  See [below](#response-payload). |
{:.grid}

#### Response Payload
The response message `payload` properties will vary based on the request `messageType`.  See message types below for details.

#### Response Target Origin
It is assumed that the EHR already knows the set of allowed web origins for each app, to be used in Web Messaging.  After launching an app, EHR SHOULD NOT process Web Messages originating from an origin outside this set.  If the app navigates users to an origin outside of this set, it SHOULD NOT depend on Web Messages reaching the EHR.

#### Example Response
As an example response, the EHR may send one return message like:

```js
window.addEventListener("message", listener);
function listener(event) {
  if (event.origin != "<the app's expected origin>") {
    return;  // Ignore unknown origins.
  }

  //
  // TODO: Handle the message here, using the contents of event.data.
  //

  // Send a response back to the app.
  const response = {
    "responseToMessageId": event.data.messageId,
    "messageType": "app.response",
    "messageId": "<some new uid>",
    // The response payload is modeled after Bundle.entry.response.
    // See: https://www.hl7.org/fhir/bundle-definitions.html#Bundle.entry.response
    "status": "success",
    "payload": {
      "location": "Example/123",
      // For errors encountered handling the request, the EHR can add an
      // OperationOutcome to contain additional information.
      // See: https://www.hl7.org/fhir/operationoutcome.html
      "outcome": {},
    }
  };
  event.source.postMessage(response, event.origin);
}
```

Then, back in the app, the message response is received and handled as shown in
this example.

```js
window.addEventListener("message", listener);
function listener(event) {
  if (event.origin != "<the EHR's origin>") {
    return;  // Ignore unknown origins.
  }

  const requestId = event.data.responseToMessageId;
  // Verify that the requestID is one that app is expecting a response for.

  if (event.data.status == "success") {
    // Success!
  } else {
    // Error handling.
  }
};
```

#### Workflow Summary
This mechanism enables a full request/response pattern. As noted, not all `request`s may receive a `response`.

NOTE: A broadcast-type pattern which involves notification messages without an initial request message is currently out of scope, even though it could be implemented with SMART Web Messaging technology.

### User-interface interactions
An embedded SMART app may improve the clinician's user experience by attempting to close itself when appropriate, or by requesting the EHR to navigate the user to an appropriate activity. 

This category of messages include: `ui.done` and `ui.launchActivity`.

The `ui.done` message type signals the EHR to close the activity hosting the SMART app.

The `ui.launchActivity` message type signals the EHR to navigate the user to another activity without closing the SMART app.

Here are some helpful, guiding principles for the intended use of `launchActivity`.
  * `launchActivity` doesn't modify EHR data itself, but it *can* hint the EHR to navigate the user to a place in the EHR workflow where the *user* could modify EHR data.
  * Data can be passed from the app to the EHR as hints, within the `launchActivity` payload.
  * For FHIR resource types, it's better to pass in a resource ID rather than duplicating resource content when providing a hint to `launchActivity`.

#### Request payload for `ui.done`
The request payload for the `ui.done` message is an empty JSON object. 

#### Request payload for `ui.launchActivity`

| Property             | Optionality | Type   | Description |
| -------------------- | ----------- | ------ | ----------- |
| `activityType`       | REQUIRED    | string | Navigation hint; see description below. |
| `activityParameters` | OPTIONAL    | object | Navigation hint; see description below. |
{:.grid}

The `activityType` property conveys an activity type drawn from the SMART Web Messaging [Activity Catalog]. The `activityType` property conveys a navigation target such as `problem-review` or `order-review`, indicating where EHR should go upon handling the launchActivity message. An activity MAY specify additional `activityParameters`.

EHRs and Apps MAY implement activities *not specified* in the [Activity Catalog] and all activities in the catalog are OPTIONAL.

The `activityParameters` property conveys parameters specific to an activity type. See the SMART Web Messaging [Activity Catalog] for details.

An example of a `ui.done` message from an app to the EHR is shown below:

```js
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messageType": "ui.done",
  "payload": {}
}, targetOrigin);
```

A SMART app can use the `ui.launchActivity` message type to request
navigation to a different activity *without* closing the app:

```js
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messageType": "ui.launchActivity",
  "payload": {
    "activityType": "problem-review",
    "activityParameters": {
      // Each ui activity defines its optional and required params.  See the
      // Activity Catalog for more details.
      "problemLocation": "Condition/123"
    }
  }
}, targetOrigin);
```

#### Response payload for `ui.launchActivity`
The `status` and `statusDetail` properties already on the `response` are sufficient to capture all outcomes of an app attempting to launch an activity. Therefore, the response payload for `ui.launchActivity` is an empty JSON object.

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
| `resource`            | REQUIRED for `scratchpad.create` and `scratchpad.update`, PROHIBITED for `scratchpad.delete`  | object | Conveys resource content as per CDS Hooks Action's `payload.resource`. |
| `location`            | REQUIRED for `scratchpad.delete` and `scratchpad.update`,  PROHIBITED for `scratchpad.create`  | string | When used for updates, the id in the `location` value SHALL match the id in the supplied resource. |
{:.grid}

The following example creates a new `ServiceRequest` in the EHR's scratchpad:

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

This example shows an update to a draft prescription in the context of a CDS
Hooks request:

```js
// Update to a better, cheaper alternative prescription
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messageType": "scratchpad.update",
  "payload": {
    "location": "MedicationRequest/123",
    "resource": {
      "resourceType": "MedicationRequest",
      "id": "123",
      "status": "draft"
      // additional details as needed
    }
  }
}, targetOrigin);
```

#### Response payload for `scratchpad.*`

The EHR responds to all `scratchpad` message types with a payload that matches
FHIR's [`Bundle.entry.response`] data model. The table below includes only
the most commonly used fields; see the FHIR specification for full details.

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `status`              | REQUIRED    | string | An HTTP response code (i.e. "200 OK"). |
| `location`            | REQUIRED if a new resource has been added to the scratchapd. | string | Conveys a relative resource URL for the new resource. |
| `outcome`             | OPTIONAL    | object | [FHIR OperationOutcome] with details if something has gone wrong. |
{:.grid}

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

For the app to then delete `MedicationRequest/456` from the EHR's scratchpad, the app sould issue this message:

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

EHR implementations MAY include additional constraints on authorization beyond these
coarse-grained scopes.  We encourage further experimentation in this direction, and will look
to implementer experience to determine whether we can standardize more granular controls.

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
