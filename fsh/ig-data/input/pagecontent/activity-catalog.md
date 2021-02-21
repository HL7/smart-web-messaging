{::comment}

  LINKS, which allow the markdown to simplify links to [link name]

{:/comment}
[FHIR Appointment]: https://www.hl7.org/fhir/appointment.html
[FHIR Bundle]: https://www.hl7.org/fhir/bundle.html
[FHIR Condition]: https://www.hl7.org/fhir/condition.html

These activites serve as navigation targets for `ui.launchActivity` messages.
They are designed to describe navigation points within an EHR environment. We
focus on defining common activites that are likely to exist across multiple EHR
systems, rather than creating a fine-grained EHR-specific workflow model. It's
important to note that this is an extensible set; while we define a set of
standardized activities using "bare" keywords like `order-review`, any EHR may
support custom activities using fully-qualified URIs like
`https://my-ehr/custom-activity-name`.

It is important to note that the activities in the activity catalog do not always align with hooks in CDS Hooks. This is because hooks in CDS Hooks represent workflow points (such as signing orders) whereas activities in SMART Web Messaging represent EHR scresns (such as the screen where clinicians tee up orders for signing). There may be some nominal overlap, but this is because the term may be used for both the workflow point and the screen (such as perhaps patient-view), but where possible, the spec will try to avoid this overlap since it is a source of confusion.

### Conformance Language
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to
be interpreted as described in RFC2119.


## `appointment-book`
This is the EHR activity where end users (usually schedulers or front-desk staff) schedule appointments for a patient.


### Parameters

| Property             | Optionality | Type   | Description |
| -------------------- | ----------- | ------ | ----------- |
| `appointmentType` | OPTIONAL    | string | The type of appointment to schedule |
| `timeSlots`       | OPTIONAL    | array  | Array of preferred timeslots for the appointment |
Note: there are perhaps additional relevant detail for booking appointments, and we welcome implementer feedback here.
{:.grid}

## `order-review`
This is the EHR activity where end users (usually clinicians) review active orders on a patient.


### Parameters

| Property             | Optionality | Type   | Description |
| -------------------- | ----------- | ------ | ----------- |
| `orderLocations` | OPTIONAL    | array  | array of order locations to highlight to end user. |
{:.grid}

## `problem-review`
Allow the EHR user to review the patient's problem list.


### Parameters

| Property             | Optionality | Type   | Description |
| -------------------- | ----------- | ------ | ----------- |
| `problemLocations` | OPTIONAL    | array  | Array of references to a pre-existing [FHIR Condition] resources to highlight to end user. |
{:.grid}
