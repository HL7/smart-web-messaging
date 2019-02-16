# smart-web-messaging
SMART Web Messaging Specification Development

# Why

Within an EHR, SMART apps can be launched automatically at specific points in the workflow, or on demand in response to a user interaction, including clicking on a suggestion from a CDS Hooks service. Once launched, a web app is typically embedded within a patient’s chart and communicates with the EHR via RESTful FHIR APIs. These RESTful APIs are great for CRUD operations on a database, but don’t enable tight workflow integration or access to draft FHIR resources that may only exist in memory on the EHR client.

For these embedded apps, there are some key use cases that SMART and CDS Hooks don't address today:

* Communicate a decision made by the clinician within the SMART app, such as placing an order, annotating a procedure with a appropriateness score or radiation count, or adding a diagnosis or condition to the patient’s chart.

* Interrogate the orders scratchpad / shopping cart, currently only known within the prescriber's EHR session.

* Allow an app to communicate UX-relevant results back to the EHR, for example, navigate to a native EHR activity, or an "I'm done signal".

Additionally, there are interesting capabilities enabled by tighter integration, for example:

* Make available text snippets for easy inclusion within a provider's note or the after visit summary.

* Save an app specific session or state identifier to the EHR for later retrieval.

* Interact with the EHR’s FHIR server directly through this messaging channel (rather than through the REST API, thereby keeping the FHIR server off of the internet).

# SMART Messaging

SMART Messaging builds on HTML 5’s [Web Messaging](https://www.w3.org/TR/webmessaging), which allows web pages to communicate across domains. Javascript’s `window.postMessage` API passes `MessageEvent` objects between windows.

A [`postMessage`-based messaging](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage) allows flexible, standards-based integration that works across windows, frames and domains, and should be readily supportable in browser controls for thick-client EHRs.

```js
// App needs to know EHR's origin.
// Add a smart_messaging_origin launch context parameter alongside the access_token
// to tell the app what the EHR's origin will be
(window.parent || window.opener).postMessage({
  "authentication": {// maybe }
  "messageId": <some guid>,
  "messageType": "scratchpad.create",
  "payload": // see below
}, targetOrigin)
```

In response, EHR sends a response like:
```js
appWindow.postMessage({
  "messageId": <some new guid>,
  "responseToMessageId": <original guid>
  "payload": { // as for FHIR's Bundle.entry.response
    "status":,		// HTTP response codes, for simplicity, consistency
    "location":,      // could be relative for scratchpad-like stuff?
    "outcome":,       // include the resource as created
  }
}, targetOrigin)
```

**For subsequent code samples, we abstract away some of the messaging details via a (theoretical) simple SMART Messaging layer, which accepts a messageType and payload and returns a promise that resolves with the response payload.**

## `messageType == ui.*`: Influence EHR UI

An embedded SMART app improves the clinician’s user experience by closing itself or requesting the EHR to navigate the user to an appropriate activity. The `ui.done` messageType instructs the EHR to close the activity hosting the SMART app, and optionally navigates the user to an alternate activity:

```js
SMART.messaging.send("ui.done", {
  "activityType": "problem-list" | "scratchpad" | ...,
  "activityParameters": {
    // Each ui activity defines its optional+required params
    "patient": "123", 
  }
}).then((responsePayload) => {...})
```

Similarly, the SMART app can use the `ui.LaunchActivity` messageType to request navigation to an alternate activity without closing the app:

```js
SMART.messaging.send("ui.launchActivity", {
  "activityType": "problem-list" | "scratchpad" | ...,
  "activityParameters": {
    // Each activity defines its optional+required params
    "patient": "123", 
  }
}).then((responsePayload) => {...})
```

The EHR responds to all `ui` messageTypes with a payload that includes a boolean success parameter and an optional `details` string:
```js
{
  "success": true | false,
  "details": string explanation for user (optionally)
}
```

## `messageType == scratchpad.*`: FHIR API Interactions

While interacting with an embedded SMART app, a clinician may make decisions that should be implemented in the EHR with minimal clicks. SMART Messaging exposes an API to the clinician’s scratchpad within the EHR, which may contain FHIR resources unavailable on the RESTful FHIR API. For example, the proposed CDS Hooks decision workflow can be implemented through SMART Messaging.  

```js
SMART.messaging.send(
  // "create"| "update"| "read" | "search" | "delete"
  "scratchpad.[interaction-name]", {
    "resourceType": "ServiceRequest", 
    "status": "draft", 
    ...
  })
```

SMART Messaging is designed to be compatible with CDS Hooks, and to implement the CDS Hooks decisions flow. For any CDS Hooks Actions array, you can create a list of SMART.messaging API calls:

* Suggestion type: used to populate the payload's `.messageType` ("create" -> "scratchpad.create", "update"->"scratchpad.update", delete->"scratchpad.delete")
* Resource body: used to populate the the payload's `.payload.resource`

For example, a proposal to update a draft prescription in the context of a CS Hooks request might look like:

```js
// Update to a better, cheaper alternative prescription
SMART.messaging.send("scratchpad.update", {
  "resource": {
    "resourceType": "MedicationRequest", 
    "id": "123",
    "status": "draft" // more details below
  }
}).then((responsePayload) => {...})
```

## Authorization with SMART scopes

SMART Messaging uses OAuth 2.0 scopes. While a simple `MedicationRequest.read` scope authorizes a SMART app to not only query for a patient's prescriptions from the RESTful FHIR server, the same scope also authorizes an app to query the EHR's SMART container for a list of unsigned, draft orders that only exist in the memory of the EHR client.
SMART Messaging enables capabilities outside of simple FHIR CRUD operations and are treated simply as additional scopes within the newly introduced SMART `messaging` scope category. For example, a SMART app could read the patient's prescribed medications, the list of not yet prescribed medications and also launch the native problem-list activity by requesting the following scopes:

* `­patient/MedicationRequest.read`
* `messaging/ui.launchActivity`

### Scope examples

```
 Location: https://ehr/authorize?
  response_type=code&
  client_id=app-client-id&
  redirect_uri=https%3A%2F%2Fapp%2Fafter-auth&
  launch=xyz123&
  scope=+launch+patient%2FMedicationRequest.read+messaging%2Fui.launchActivity+openid+profile&
  state=98wrghuwuogerg97&
  aud=https://ehr/fhir
```

Following the OAuth 2.0 handshake, the authorization server returns the authorized SMART launch parameters alongside the access_token. Note the `scope` and `smart_messaging_origin` values:

```
 {
  "access_token": "i8hweunweunweofiwweoijewiwe",
  "token_type": "bearer",
  "expires_in": 3600,
  "scope": "patient/Observation.read patient/Patient.read messaging/ui.launchActivity",
  "smart_messaging_origin": "https://ehr.example.org",
  "state": "98wrghuwuogerg97",
  "patient":  "123",
  "encounter": "456",
}
```

## Limitations

Using a `postMessage`-based message allows flexible, standards-based integration that works across windows and frames, and should be readily supportable in browser controls for thick-client EHRs.

The use of web messaging requires the app to be a web application, which is either embedded within an iframe or launched from a window.

SMART messaging is not a context synchronization specification (see http://fhircast.org for that). Rather, it’s a collection of functions available to a web app embedded within an EHR which supports tight workflow integration.   

## Alternatives considered (with pro/con analysis)

In deciding on `postMessage`, we considered several alternative techniques:


### `window.postMessage` (<-- **selected option**)

Details: Message channel abstraction built on `postMessage`; see proposal above.

* **Pro**
  * good for queries with async responses
  * works for bidirectional messaging

* **Con**
  * web apps only (not native mobile)
  * IE<=10 [may be broken](https://stackoverflow.com/questions/16226924/is-cross-origin-postmessage-broken-in-ie10) with apps in new tabs -- but iframed apps probably work fine

### Redirect to an "I'm done" URL. 

Details: This is how the pre-1.0 CDS Hooks specification worked, and how the original sandbox worked

* **Pro**
  * simple browser construct
  * might work for native mobile apps too

* **Con**
  * hard to pass detailed payloads
  * hard to authenticate payloads.
  * enforces the user seeing a blank page
  * doesn't allow a response payload
  * doesn't allow EHR to send messages to the app (one-way channel only)


### Pass along JS or decorate web browser control with a method

Details: For example, the access token response coudl include a values like
`"js_to_load": "https://otherdomain.example.org/ehr/actionPerformer.js"`, and the app would create a  `<script
src="https://otherdomain.example.org/ehr/actionPerformer.js"/>` tag to load the relevant code. Then the app would have access to `smartMessaging.send()`, with a list of functions and contracts...


* **Pro**
  * gives EHRs flexibility for diverse architectures
  * works with web and mobile apps

* **Con**
  * opens up a large attack surface.
  * Nobody wants to get security review for this.

### EHR hosts a HTTP API endpoint

Details: This is effectively a standalone REST API endpoint for managing messages

* **Pro**
  * lots of experience, well understood security properties.
  * works with web and native apps

* **Con**
  * EHR needs to route messages from its server back to the frontend
  * EHR UI needs to understand inbound messages
  * EHR can't easily send messages back to the app; it's a one-way channel unless you add in (long) polling

### EHR hosts a Web Socket endpoint

Details: This is similar to the standalone REST API endpoint option

* **Pro**
  * works with web and native apps

* **Con**
  * EHR needs to route messages from its server back to the frontend
  * EHR UI needs to understand inbound messages
  * Inconsistent/spotty browser support (?)


### SignalR, socket.io

Details: Rely on a full-fledged library that supports multiple modalities of exchange with fallbacks

* **Pro**
  * enables bidirectional communication

* **Con**
  * not a standard; this pushes implementation details that we can't control

### FHIRCast

Details: Same tech as HTTP API (+experimental Websockets)

* **Pro**
  * handles context synchronization

* **Con**
  * EHR needs to route messages from its server back to the frontend
  * EHR UI needs to understand inbound messages
  * Unsuitable for static apps (app needs a REST API endpoint for async responses or incoming messages)

## Open Questions

1. Does the app authenticate in the the postMessage body? Should the app pass the access_token in the postmessage to authenticate itself? 

* Currently, we don’t have this in the above, because of the concern around bringing the access_token to the client in javascript, and because the host having launched the app is what authenticates the app.
Should there be something that is exchanged between the app and the host to authenticate the app at all? Or is the host having launched the app enough authorization for the app? 

2. Does access expire with SMART access_tokens?


3. How does the app know what messageTypes are supported? 
There are two aspects to this:
* Does the container at all support messaging?
* What messages are supported in this context?

4. Does (3) above need to be an initial handshake postMessage? Do scopes in access_token already meet this need? Or do we need something like added details in a well-known/smart-configuration.json / documentation?