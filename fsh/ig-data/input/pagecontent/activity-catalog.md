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

| Activity Name      | Description | Parameters |
| ------------------ | ----------- | ---------- |
| `appointment-book` | See [CDS Hooks `appointment-book`]                | `appointments`: [FHIR Bundle] of [FHIR Appointment] resources in draft status, and any other supporting data. |
| `order-sign`       | See [CDS Hooks `order-sign`]                      | `draftOrders`: array of draft orders to include in the scratchpad. (Note that for more fine-grained control, an app may query/create/update orders using the `scratchpad.*` SMART Web Messaging API before navigating to this activity.  In this case, the `draftOrders` array may be omitted fom the activity parameters.) |
| `problem-add`      | Add a new problem to the patieint's problem list. | `problem`: [FHIR Condition] resource, to pre-populate the data entry screen. |
{:.grid}
