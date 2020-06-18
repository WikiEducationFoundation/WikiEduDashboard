import dayjs from 'dayjs';
import minMax from 'dayjs/plugin/minMax';

dayjs.extend(minMax);
class DateCalculator {
  constructor(beginning, ending, loopIndex, opts) {
    this.beginning = beginning;
    this.ending = ending;
    this.loopIndex = loopIndex;
    this.opts = opts;
  }

  startDate() {
    const index = this.opts.zeroIndexed === true ? this.loopIndex : this.loopIndex - 1;
    return dayjs(this.beginning).startOf('week').add(7 * index, 'day');
  }

  start() {
    return this.startDate().format('MM/DD');
  }

  endDate() {
    return dayjs.min(this.startDate().clone().add(6, 'day'), dayjs(this.ending));
  }

  end() {
    return this.endDate().format('MM/DD');
  }
}

export default DateCalculator;
