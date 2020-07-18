
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
