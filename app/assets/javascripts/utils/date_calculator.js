import { addDays, format, min, startOfWeek } from 'date-fns';
import { toDate } from './date_utils';

class DateCalculator {
  constructor(beginning, ending, loopIndex, opts) {
    this.beginning = beginning;
    this.ending = ending;
    this.loopIndex = loopIndex;
    this.opts = opts;
  }
  static calculateDates(timeline_start, timeline_end, index, options = { zeroIndexed: true }) {
    const dateCalc = new DateCalculator(timeline_start, timeline_end, index, options);
    const datesStr = `${dateCalc.start()} - ${dateCalc.end()}`;
    return datesStr;
  }
  startDate() {
    const index = this.opts.zeroIndexed === true ? this.loopIndex : this.loopIndex - 1;
    return addDays(startOfWeek(toDate(this.beginning)), 7 * (index || 0));
  }

  start() {
    return format(this.startDate(), 'MM/dd');
  }

  endDate() {
    return min([addDays(this.startDate(), 6), toDate(this.ending)]);
  }

  end() {
    return format(this.endDate(), 'MM/dd');
  }
}

export default DateCalculator;
