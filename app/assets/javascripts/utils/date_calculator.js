import moment from 'moment';

class DateCalculator {
  constructor(beginning, ending, loopIndex, opts) {
    this.beginning = beginning;
    this.ending = ending;
    this.loopIndex = loopIndex;
    this.opts = opts;
  }

  startDate() {
    const index = this.opts.zeroIndexed === true ? this.loopIndex : this.loopIndex - 1;
    return moment(this.beginning).startOf('week').add(7 * index, 'day');
  }

  start() {
    return this.startDate().format('MM/DD');
  }

  endDate() {
    return moment.min(this.startDate().clone().add(6, 'day'), moment(this.ending));
  }

  end() {
    return this.endDate().format('MM/DD');
  }
}

export default DateCalculator;
