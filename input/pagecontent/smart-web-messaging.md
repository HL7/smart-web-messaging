{::comment}

  COMMON TERMS, which will reveal a hover-text definition in the IG when viewed.
  
  NOTE: When adding an abbreviation to this list, also add the same abbreviation
  to the List of Abbreviations section near the end of this IG.

{:/comment}
*[API]: Application Programming Interface
*[CDS]: Clinical Decision Support
*[CPOE]: Computerized Physician Order Entry
*[CRUD]: Create Read Update Delete
*[EHR]: Electronic Health Record
*[EHRs]: Electronic Health Record
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
[FHIR CodeableConcept]: https://hl7.org/fhir/datatypes.html#CodeableConcept
[FHIR OperationOutcome]: https://www.hl7.org/fhir/operationoutcome.html
[FHIRCast]: https://fhircast.org
[HTML5]: https://html.spec.whatwg.org/multipage
[HTML5's Web Messaging]: https://html.spec.whatwg.org/multipage/web-messaging.html
[Introduction]: ./index.html
[JSON (RFC7159)]: https://tools.ietf.org/html/rfc7159
[`MessageEvent`]: https://html.spec.whatwg.org/multipage/comms.html#messageevent
[OAuth]: https://oauth.net/
[OAuth 2.0]: https://oauth.net/2/
[OAuth scopes]: https://oauth.net/2/scope/
[RESTful FHIR API]: https://hl7.org/fhir/http.html
[RFC2119]: https://tools.ietf.org/html/rfc2119
[SMART applications]: https://hl7.org/fhir/smart-app-launch/index.html
[`window.postMessage`]: https://html.spec.whatwg.org/multipage/web-messaging.html#posting-messages

SMART Web Messaging enables tight UI integration between EHRs and embedded SMART apps via [HTML5's Web Messaging].  SMART Web Messaging allows applications to push unsigned orders, note snippets, risk scores, or UI suggestions directly to the clinician's EHR session.  Built on the browser's javascript [`window.postMessage`] function, SMART Web Messaging is a simple, native API for health apps embedded within the user's workflow.

Refer to the [Introduction] page for a overview, if needed.

### Conformance Language
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to be interpreted as described in [RFC2119].

#### Scratchpad
Throughout this IG, references to a "scratchpad" refer to an EHR capability where FHIR-structured data can be stored without the expectation of being persisted "permanently" in a FHIR server. The scratchpad can be thought of as a shared memory area, consisting of "temporary" FHIR resources that can be accessed and modified by either an app or the EHR itself.  Each resource on the scratchpad has a temporary unique id (its scratchpad "location").

A common use of the scratchpad is to hold the contents of a clinician's "shopping cart" -- i.e., data that only exist during the clinician's session and may not have been finalized or made available through in the EHR's FHIR API. At the end of a user's session, selected data from the scratchpad can be persisted to the EHR's FHIR server (e.g., a "checkout" experience, following the shopping cart metaphor).

### SMART Web Messaging
SMART Web Messaging builds on [HTML5's Web Messaging] specification, which
allows web pages to communicate across domains.  In JavaScript, calls to
[`window.postMessage`] pass [`MessageEvent`] objects between windows.

A [`window.postMessage`]-based messaging approach allows flexible,
standards-based integration that works across windows, frames and domains, and
should be readily supportable in browser controls for any EHR capable of 
embedding a web application.

Messages, often in the form or request/response, can originate from an
application to the EHR client.  Messages initiated from the EHR to an
application is currently out of scope, but is planned for inclusion in a
future version of this specification.

Requesters SHALL be capable of receiving at most one response message to an
initial request message.  All response messages will contain a populated
`responseToMessageId` field, which correlates to an initial `messageId` field
sent in a request message.  See the following sections for more details.

#### Request Parameters
For the purposes of SMART Web Messaging, a [`window.postMessage`] call from a
caller SHALL contain a JSON message object with the following properties:

| Property          | Optionality  | Type   | Description |
| ----------------- | ------------ | ------ | ----------- |
| `messagingHandle` | REQUIRED     | string | The content of the `smart_web_messaging_handle` property of the [OAuth] access token response JSON payload.  ([Details below.](#authorization-with-smart-scopes)). |
| `messageId`       | REQUIRED     | string | A unique ID for this message generated by the application. |
| `messageType`     | REQUIRED     | string | The type of this message (e.g., `ui.done`, `scratchpad.update`, `status.handshake`, etc). |
| `payload`         | REQUIRED     | object | The message content as specified by the `messageType`.  See below. |
{:.grid}

This message object MUST be passed to [`window.postMessage`] using a valid `targetOrigin` parameter.  The caller MUST provide the `smart_web_messaging_origin` property to the receiver in the initial SMART launch context alongside the `access_token`.  Callers SHOULD NOT use `"*"` for the `targetOrigin` parameter for [security reasons](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage#Security_concerns).

{::comment}

  TODO: include an example of using the SMART app launch client here, and extracting the smart_web_messaging_origin from the launch context.  Link to the javascript FHIR client?
  See: https://github.com/HL7/smart-web-messaging/issues/18

{:/comment}

##### Handshake
The purpose of the handshake is to allow apps and EHRs to determine, just after
launch time, if web messaging is enabled in the other; and possibly to discover
what capabilities the other supports.

Either an app, or the EHR, MAY initiate an OPTIONAL handshake message sequence,
using the value `status.handshake` as the value for the `messageType` and an
empty object for the `payload`.  The receiver of a handshake request message
SHOULD respond with an appropriate handshake response message, and MAY provide
an OPTIONAL `error` [FHIR Coding] parameter.

Extensions MAY be used for handshake requests and responses, and MAY be used to
advertise capabilities.


#### Example Request
An example call from an app to the EHR client is presented below.

```js
// When a SMART app is launched embedded in an iframe, window.parent and window.self
// are different objects, with window.parent being the recipient of MessageEvents.
// When a SMART app is launched standalone, window.parent and window.self are the same.
// In that case, window.opener will be the object receiving MessageEvents.
const targetWindow = window.parent !== window.self ? window.parent : window.opener;

// Read the smart_web_messaging_origin property from the launch context (alongside the access_token).
// This value provides the app with the EHR client's expected target origin.
const targetOrigin = "<smart_web_messaging_origin> from SMART launch context";

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
  // YOUR CODE HERE: Handle the message here by using the contents of event.data.
  //

  // Send a response back to the app.
  const response = {
    ...  // See below for more details on the response properties.
  };
  event.source.postMessage(response, event.origin);
});
```

#### Response Properties
The receiver SHALL send a response message with the following properties:

| Property              | Optionality  | Type   | Description |
| --------------------- | ------------ | ------ | ----------- |
| `messageId`           | REQUIRED     | string | A unique ID for this message generated by the caller. |
| `responseToMessageId` | REQUIRED     | string | The `messageId` of the received message that this message is in response to. |
| `payload`             | REQUIRED     | object | The message content as specified by the `messageType` of the request message.  See [below](#response-payload). |
{:.grid}

#### Response Payload
The response message `payload` properties will vary based on the request `messageType`.  See message types below for details.

#### Response Target Origin
It is assumed that the EHR already knows the set of allowed web origins for each
app, to be used in Web Messaging.  After launching an app, EHR SHOULD NOT process
Web Messages originating from an origin outside this set.  If the app navigates
users to an origin outside of this set, it SHOULD NOT depend on Web Messages
reaching the EHR.

#### Detailed Example Response
In a more detailed example response, the EHR may send one return message like:

```js
window.addEventListener("message", function(event) {
  if (event.origin != "<the app's expected origin>") {
    return;  // Ignore unknown origins.
  }

  //
  // YOUR CODE HERE: Handle the message here, using the contents of event.data.
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

NOTE: A broadcast-type pattern which involves notification messages without an initial request
message is currently out of scope, even though it could be implemented with SMART Web Messaging
technology.

### Influence the EHR UI: `ui.*` message type
An embedded SMART app may improve the clinician's user experience by attempting
to close itself when appropriate, or by requesting the EHR automatically
navigate the user to an appropriate 'next' activity.  Messages that affect the
EHR UI will have a `messageType` that matches the pattern `ui.*`.

The `ui` category includes messages: `ui.done` and `ui.launchActivity`.

The `ui.done` message type signals the EHR to close the activity hosting the
SMART app.

The `ui.launchActivity` message type signals the EHR to navigate the user to another
activity without closing the SMART app.

Here are some helpful, guiding principles for the intended use of `launchActivity`.
  * `launchActivity` doesn't modify EHR data itself, but it *can* hint the EHR to
    navigate the user to a place in the EHR workflow where the *user* could modify
    EHR data.
  * Data can be passed from the app to the EHR as hints, within the `launchActivity`
    payload.
  * For supported resource types, it's better to pass in a scratchpad resource ID
    rather than duplicating resource content when providing a hint to `launchActivity`.

#### Request payload for `ui.done` and `ui.launchActivity`

| Property             | Optionality | Type   | Description |
| -------------------- | ----------- | ------ | ----------- |
| `activityType`       | REQUIRED for `ui.launchActivity`, PROHIBITED for `ui.done` | string | Navigation hint; see description below. |
| `activityParameters` | REQUIRED for `ui.launchActivity`, PROHIBITED for `ui.done` | object | Navigation hint; see description below. |
{:.grid}

The `activityType` property conveys an activity type drawn from the SMART Web
Messaging [Activity Catalog]. In general, these activities follow the same
naming conventions as entries in the CDS Hooks catalog (`noun-verb`), and will
align with CDS Hooks catalog entries where feasible. The `activityType` property
conveys a navigation target such as `problem-review` or `order-review`, indicating
where EHR should go to after the ui message has been handled. An activity MAY
specify additional parameters that can be included in the call as additional
properties.

EHRs and Apps MAY implement activities *not specified* in the [Activity Catalog] and
that all activities in the catalog are OPTIONAL.

The `activityParameters` property conveys parameters specific to an activity
type. See the SMART Web Messaging [Activity Catalog] for details.

An example of a `ui.done` message from an app to the EHR is shown below:

```js
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
  "messageType": "ui.done",
  "payload": {}
}, targetOrigin);
```

A SMART app can use the `ui.launchActivity` message type to request
navigation to a different activity *without* closing the app:

```js
targetWindow.postMessage({
  "messageId": "<some new uid>",
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
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

#### Response payload for `ui.done` and `ui.launchActivity`

| Property  | Optionality | Type    | Description |
| --------- | ----------- | ------- | ----------- |
| `status`  | REQUIRED    | `code` | Either `success` or `failure`.  See [`LaunchStatusCode`](CodeSystem-launch-status-code-system.html) for details. |
| `statusDetail` | OPTIONAL | [FHIR CodeableConcept] | Populated with a description of the response status code. |
{:.grid}

##### `LaunchStatusCode`

| System | Version | Code | Display |
| ------ | ------- | ---- | ------- |
| https://hl7.org/fhir/uv/smart-web-messaging | from v0.1 | `success` | Success |
| https://hl7.org/fhir/uv/smart-web-messaging | from v0.1 | `error`   | Failure |
{:.grid}

See more details [here](CodeSystem-launch-status-code-system.html).

The EHR SHALL respond to all `ui` message types with a payload that includes a
`status` parameter and an optional `statusDetail` [FHIR CodeableConcept]:

```js
clientAppWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<uid from the client's request>",
  "payload": {
    "status": "success",
    "statusDetail": {
      "text": "string explanation for user (optional)"
    }
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

#### `scratchpad` operations
Scratchpad operations are conducted through an exchange of a *request* from an
application and a *response* from an EHR.

The sections below detail the request and response payload requirements.  For
each of the response section below, the provided table includes only
the most commonly used response payload fields; for full details, see the
[FHIR specification](https://hl7.org/fhir/bundle-definitions.html#Bundle.entry.response).

##### `scratchpad.create`

###### Request `payload`

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `resource`            | REQUIRED    | object | Conveys resource content as per the [CDS Hooks Action] `payload.resource`. |
{:.grid}

###### Response `payload`

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `status`              | REQUIRED    | string | An HTTP response code (i.e. "200 OK"). |
| `location`            | REQUIRED if a new resource has been added to the scratchapd. | string | Takes the form `ResourceType/Id`. |
| `outcome`             | OPTIONAL    | object | [FHIR OperationOutcome] resulting from the message action. |
{:.grid}

###### Examples

The following example creates a new `ServiceRequest` in the EHR's scratchpad:

```js
// From app -> EHR
ehrWindow.postMessage({
  "messageId": "<some new uid>",
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
  "messageType": "scratchpad.create",
  "payload": {
    "resource": {
      "resourceType": "ServiceRequest",
      "status": "draft",
      // additional details as needed
    }
  }
}, ehrOrigin);
```

The EHR then performs the requested operation, creating an object in an internal
scratchpad and assigning it id `123` before finally responding with:

```js
// From EHR -> app
appWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<corresponding request messageId>",
  "payload": {
    "status": "201 Created",
    "location": "ServiceRequest/123"
  }
}, appOrigin);
```

##### `scratchpad.read`

###### Request `payload`

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `location`            | OPTIONAL    | string | Takes the form `ResourceType/Id` when provided.  |
{:.grid}

###### Response `payload`

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `status`              | REQUIRED    | string | An HTTP response code (i.e. "200 OK" or "404 NOT FOUND"). |
| `resources`           | OPTIONAL    | object | [FHIR Bundle] containing zero or more resources matching the requested `location`. |
| `outcome`             | OPTIONAL    | object | [FHIR OperationOutcome] resulting from the message action. |
{:.grid}

All resources included in the response `resources` Bundle SHALL contain a
`location` value which matches the value specified in the request `location`
field; however, if no value was provided in the request, the response Bundle
SHALL contain the *full* scratchpad contents.

If a `location` was specified in a request but not found in the scratchpad,
or if there are no entries in the scratchpad, the `resources` property may be
omitted from the response payload.

###### Examples

---

This example shows how an app might request the contents of a single resource
from the scratchpad, `ServiceRequest/123`.

```js
// From app -> EHR
ehrWindow.postMessage({
  "messageId": "<some new uid>",
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
  "messageType": "scratchpad.read",
  "payload": {
    "location": "ServiceRequest/123"
  }
}, ehrOrigin);
```

Assuming the resource exists, the EHR could return it to the app like this:

```js
// From EHR -> app
appWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<corresponding request messageId>",
  "payload": {
    "status": "200 OK",
    "resources": {
      "id": "<some new uid>",
      "resourceType": "Bundle",
      "type": "collection",
      "entry": [
        {
          "fullUrl": "ServiceRequest/123",
          "resource": {
            "resourceType": "ServiceRequest",
            "id": "123",
            "status": "draft",
            "intent": "proposal",
            "subject": {
              "reference": "http://example.com/Patient/123"
            }
          }
        }
      ]
    }
  }
}, appOrigin);
```

---

This example shows how an app might inspect the entire contents of the
scratchpad.

```js
// From app -> EHR
ehrWindow.postMessage({
  "messageId": "<some new uid>",
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
  "messageType": "scratchpad.read"
}, ehrOrigin);
```

The EHR could then respond with the full contents of the scratchpad in one
bundle.

```js
// From EHR -> app
appWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<corresponding request messageId>",
  "payload": {
    "status": "200 OK",
    "resources": {
      "id": "<some new uid>",
      "resourceType": "Bundle",
      "type": "collection",
      "entry": [
        {
          "fullUrl": "ServiceRequest/1",
          "resource": {
            "resourceType": "ServiceRequest",
            "id": "1",
            "status": "draft",
            "intent": "proposal",
            "subject": {
              "reference": "http://example.com/Patient/123"
            }
          }
        },
        {
          "fullUrl": "MedicationRequest/1",
          "resource": {
            "resourceType": "MedicationRequest",
            "id": "1",
            "status": "draft",
            "intent": "proposal",
            "medicationCodeableConcept": {
              "coding": [
                {
                  "system": "http://snomed.info/sct",
                  "code": "108761006",
                  "display": "Capecitabine-containing product"
                }
              ]
            },
            "subject": {
              "reference": "http://example.com/Patient/123"
            }
          }
        }
      ]
    }
  }
}, appOrigin);
```

---

This example shows how an app might inspect the entire contents of the
scratchpad.

```js
// From app -> EHR
ehrWindow.postMessage({
  "messageId": "<some new uid>",
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
  "messageType": "scratchpad.read"
}, ehrOrigin);
```

Assuming the scratchpad is empty, the EHR could respond to the app with:

```js
// From EHR -> app
appWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<corresponding request messageId>",
  "payload": {
    "status": "200 OK"
  }
}, appOrigin);
```

---

This example shows how an app might request the contents of a single resource
from the scratchpad, `ServiceRequest/321`.

```js
// From app -> EHR
ehrWindow.postMessage({
  "messageId": "<some new uid>",
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
  "messageType": "scratchpad.read",
  "payload": {
    "location": "ServiceRequest/321"
  }
}, ehrOrigin);
```

Assuming the resource does *not* exist, the EHR could return the following:

```js
// From EHR -> app
appWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<corresponding request messageId>",
  "payload": {
    "status": "404 NOT FOUND"
  }
}, appOrigin);
```

##### `scratchpad.update`

###### Request `payload`

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `resource`            | REQUIRED    | object | Conveys resource content as per CDS Hooks Action's `payload.resource`. |
| `location`            | REQUIRED    | string | Takes the form `ResourceType/Id`.  |
{:.grid}

The `location` value, when parsed for `ResourceType` and `Id`, SHALL match the corresponding `ResourceType` and `Id` fields present in the `resource` property.

###### Response `payload`

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `status`              | REQUIRED    | string | An HTTP response code (i.e. "200 OK"). |
| `outcome`             | OPTIONAL    | object | [FHIR OperationOutcome] resulting from the message action. |
{:.grid}

###### Examples

This example shows an update to a draft prescription in the context of a CDS
Hooks request:

```js
// app -> EHR: Update to a better, cheaper alternative prescription
ehrWindow.postMessage({
  "messageId": "<some new uid>",
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
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
}, ehrOrigin);
```

The EHR then performs the requested update, modifying an object in the
scratchpad before finally responding with:

```js
// From EHR -> app
appWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<corresponding request messageId>",
  "payload": {
    "status": "200 OK",
    "location": "MedicationRequest/123"
  }
}, appOrigin);
```

##### `scratchpad.delete`

###### Request `payload`

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `location`            | REQUIRED    | string | Takes the form `ResourceType/Id`.  |
{:.grid}

###### Response `payload`

| Property              | Optionality | Type   | Description |
| --------------------- | ----------- | ------ | ----------- |
| `status`              | REQUIRED    | string | An HTTP response code (i.e. "200 OK"). |
| `outcome`             | OPTIONAL    | object | [FHIR OperationOutcome] resulting from the message action. |
{:.grid}

###### Examples

For the app to delete `MedicationRequest/456` from the EHR's scratchpad, the app should issue this message:

```js
// app -> EHR
ehrWindow.postMessage({
  "messageId": "<some new uid>",
  "messagingHandle": "<smart_web_messaging_handle> from SMART launch context",
  "messageType": "scratchpad.delete",
  "payload": {
    "location": "MedicationRequest/456"
  }
}, ehrOrigin);
```

Assuming the delete operation completed, the EHR could respond with:

```js
// From EHR -> app
appWindow.postMessage({
  "messageId": "<some new uid>",
  "responseToMessageId": "<corresponding request messageId>",
  "payload": {
    "status": "200 OK",
    "location": "MedicationRequest/456"
  }
}, appOrigin);
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
`scope`, `smart_web_messaging_handle`, and `smart_web_messaging_origin` values:

```json
 {
  "access_token": "i8hweunweunweofiwweoijewiwe",
  "token_type": "bearer",
  "expires_in": 3600,
  "scope": "patient/Observation.read patient/Patient.read messaging/ui.launchActivity",
  "smart_web_messaging_handle": "bws8YCbyBtCYi5mWVgUDRqX8xcjiudCo",
  "smart_web_messaging_origin": "https://ehr.example.org",
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
Several design approaches were considered when first designing this
specification, and some of those candidate designs are captured for posterity 
in the section linked below.

See [Alternatives Considered].

### Security considerations
In the current proposal, we provide infrastructure for servers to correlate Web
Messaging requests with a specific SMART App Launch context, through the
`smart_web_messaging_handle`.  However, we do not require that servers make use of
this property.  Refer to the historical [discussion and rationale here](https://github.com/HL7/smart-web-messaging/pull/4)
for background context.

### List of Abbreviations
The following acronyms and abbreviations are used throughout the document and
are provided here for the benefit of printed-copy IG implementers and readers.

| Abbreviation | Meaning |
| ------------ | ------- |
| [API]   | Application Programming Interface |
| [CDS]   | Clinical Decision Support |
| [CPOE]  | Computerized Physician Order Entry |
| [CRUD]  | Create Read Update Delete |
| [EHR]   | Electronic Health Record |
| [OAuth] | An open standard for access delegation, commonly used as a way for Internet users to grant websites or applications access to their information on other websites but without giving them the passwords. |
| [UX]    | User Experience |
{:.grid}
