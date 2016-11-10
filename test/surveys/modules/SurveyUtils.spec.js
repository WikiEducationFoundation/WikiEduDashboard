import '../../testHelper';
import Utils from '../../../app/assets/javascripts/surveys/modules/SurveyUtils.js';

describe('.parseConditionalString', () => {
  it('handles the case of a multi conditional', () => {
    const testString = '242|=|Very_unsatisfied|multi';
    const output = Utils.parseConditionalString(testString);
    expect(output.question_id).to.eq('242');
    expect(output.operator).to.eq('=');
    expect(output.value).to.eq('Very_unsatisfied');
    expect(output.multi).to.eq(true);
  });
});
