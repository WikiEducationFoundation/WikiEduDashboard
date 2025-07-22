import '../../testHelper';
import Utils from '../../../app/assets/javascripts/surveys/modules/SurveyUtils.js';

describe('.parseConditionalString', () => {
  test('handles the case of a multi conditional', () => {
    const testString = '242|=|Very_unsatisfied|multi';
    const output = Utils.parseConditionalString(testString);
    expect(output.question_id).toBe('242');
    expect(output.operator).toBe('=');
    expect(output.value).toBe('Very_unsatisfied');
    expect(output.multi).toBe(true);
  });
});
