import '../testHelper';
import DateCalculator from '../../app/assets/javascripts/utils/date_calculator.coffee';

describe('DateCalculator', () => {
  describe('start', () => {
    describe('loop is zeroIndexed', () => {
      it('returns the formatted start of the nth week (as provided to the constructor)', () => {
        const calculator = new DateCalculator('2016-01-01', '2016-12-31', 1, { zeroIndexed: true });
        expect(calculator.start()).to.eq('01/03');
      });
    });
    describe('loop is not zeroIndexed', () => {
      it('returns the formatted start of the n - 1 week (as provided to the constructor)', () => {
        const calculator = new DateCalculator('2016-01-01', '2016-12-31', 1, { zeroIndexed: false });
        expect(calculator.start()).to.eq('12/27');
      });
    });
  });
  describe('end', () => {
    describe('last day of the week we started on is before course end', () => {
      it('returns the formatted start of the nth week (as provided to the constructor)', () => {
        const calculator = new DateCalculator('2016-01-01', '2016-12-31', 1, { zeroIndexed: false });
        expect(calculator.end()).to.eq('01/02');
      });
    });
    describe('last day of the week we started on is after course end', () => {
      it('returns the formatted course end', () => {
        const calculator = new DateCalculator('2016-01-01', '2016-12-31', 60, { zeroIndexed: false });
        expect(calculator.end()).to.eq('12/31');
      });
    });
  });
});
