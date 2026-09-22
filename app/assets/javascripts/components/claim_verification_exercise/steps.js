/*
  The steps of the fact-verification exercise that happen before the verification
  form: picking an article, then picking a claim within the article viewer. The
  form's own steps are declared server-side in
  config/claim_verification_exercise.yml and arrive with their headings already
  composed, so these two are the only ones the client numbers itself.

  Numbering works the same way on both sides — derived from position, not written
  into the copy — and continues across the boundary: the config's
  `first_step_number` must be the next number after the steps listed here.
*/

const PRE_FORM_STEPS = ['select_article', 'select_claim'];

// "Step 2: Choose claim to verify", using the same format string the form's
// steps compose (see ClaimVerification::FormStep#heading).
export const stepHeading = id => I18n.t('claim_verification.step_heading', {
  number: PRE_FORM_STEPS.indexOf(id) + 1,
  name: I18n.t(`claim_verification.step_${id}`),
});
