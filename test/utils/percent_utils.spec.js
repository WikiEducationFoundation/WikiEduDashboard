import '../testHelper';
import { percentLabel } from '../../app/assets/javascripts/utils/percent_utils';

describe('percentLabel', () => {
  it('adds a percent sign to a value', () => {
    expect(percentLabel('87.5')).toBe('87.5%');
    expect(percentLabel(0)).toBe('0%');
  });

  it('shows a dash when there is nothing to take a percentage of', () => {
    expect(percentLabel(null)).toBe('—');
    expect(percentLabel(undefined)).toBe('—');
  });
});
