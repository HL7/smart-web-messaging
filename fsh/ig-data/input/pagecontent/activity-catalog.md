{::comment}

  LINKS, which allow the markdown to simplify links to [link name]

{:/comment}
[CDS Hooks `appointment-book`]: https://cds-hooks.org/hooks/appointment-book/
[CDS Hooks `order-sign`]: https://cds-hooks.org/hooks/order-sign/
[FHIR Appointment]: https://www.hl7.org/fhir/appointment.html
[FHIR Bundle]: https://www.hl7.org/fhir/bundle.html
[FHIR Condition]: https://www.hl7.org/fhir/condition.html

These activites serve as navigation targets for `ui.launchActivity` messages.
They are designed to describe navigation points within an EHR environment. We
focus on defining common activites that are likely to exist across multiple EHR
systems, rather than creating a fine-grained EHR-specific workflow model. It's
important to note that this is an extensible set; while we define a set of
standardized activities using "bare" keywords like `order-sign`, any EHR may
support custom activities using fully-qualified URIs like
`https://my-ehr/custom-activity-name`.

Standardized activities follow the same naming convention as CDS Hooks, with
`noun-verb` form. In addition to following the same naming convention, we'll
align with the actual names of existing CDS Hooks activities where feasible.

### Conformance Language
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this specification are to
be interpreted as described in RFC2119.


## `appointment-book`
See [CDS Hooks `appointment-book`]

### Parameters
| Name                   | Optionality | Description |
| ---------------------- | ----------- | ----------- |
| `appointmentLocations` | REQUIRED    | [FHIR Bundle] of [FHIR Appointment] resource locations in draft status, and any other supporting data. |
{:.grid}


## `order-review`
See [CDS Hooks `order-sign`] for a similar operation.

### Parameters
| Name                  | Optionality | Description |
| --------------------- | ----------- | ----------- |
| `draftOrderLocations` | REQUIRED    | array of draft order locations (references to) already existing in the scratchpad. See the `scratchpad.*` operations. |
{:.grid}


## `problem-review`
Allow the EHR user to add a new problem to the patieint's problem list.

### Parameters
| Name              | Optionality | Description |
| ----------------- | ----------- | ----------- |
| `problemLocation` | REQUIRED    | [FHIR Condition] resource reference to a pre-existing resource that is used by the EHR to pre-populate the data entry screen presented to the user. |
{:.grid}
