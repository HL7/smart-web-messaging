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

|Activity Name|Description|Parameters|
|---|---|---|
|`order-sign`|See [CDS Hooks](https://cds-hooks.org/hooks/order-sign/)|`draftOrders`: array of draft orders to include in the scratchpad. (Note that for more fine-grained control, an app may query/create/update orders using the `scratchpad.*` SMART Web Messaging API before navigating to this activity. In this case, the `draftOrders` array may be omitted fom the activity parameters.)|
|`appointment-book`|See [CDS Hooks](https://cds-hooks.org/hooks/appointment-book/)|`appointments`: FHIR Bundle of Appointment resources in draft status, and any other supporting data|
|`problem-add`|Add  a new problem to the patieint's problem list|`problem`: FHIR Condition resource, to pre-populate the data entry screen|

<table class='grid'><thead><tr><th>Activity Name</th><th>Description</th><th>Parameters</th></tr></thead>
<tbody>
<tr>
  <td><code class="highlighter-rouge">order-sign</code></td>
  <td>See <a href="https://cds-hooks.org/hooks/order-sign/">CDS Hooks</a></td>
  <td><code class="highlighter-rouge">draftOrders</code>: array of draft orders to include in the scratchpad. Note that for more fine-grained control, an app may query/create/update orders using the `scratchpad.*` SMART Web Messaging API before navigating to this activity. In this case, the <code class="highlighter-rouge">draftOrders</code> array may be omitted fom the activity parameters.</td>
</tr>
<tr>
  <td><code class="highlighter-rouge">appointment-book</code></td>
  <td>See <a href="https://cds-hooks.org/hooks/appointment-book/">CDS Hooks</a></td>
  <td><code class="highlighter-rouge">appointments</code>: FHIR Bundle of Appointment resources in draft status, and any other supporting data.</td>
</tr>
<tr>
  <td><code class="highlighter-rouge">problem-add</code></td>
  <td>Add a new problem to the patieint's problem list</td>
  <td><code class="highlighter-rouge">problem</code>: FHIR Condition resource, to pre-populate the data entry screen.</td>
</tr>
</tbody>
</table>
