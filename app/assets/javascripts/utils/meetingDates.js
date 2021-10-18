import moment from 'moment';

// this method adds date to meetings

const MeetingDates = (start, meetingsString) => {
  const meetings = meetingsString.split('').slice(1, meetingsString.length - 1).join('').split(', ');
  const dates = [];
  for (let i = 0; i < meetings.length; i += 1) {
    switch (meetings[i]) {
      case 'Sun':
        dates.push(`${moment(start).format('dddd Do')}`);
        break;
     case 'Mon':
        dates.push(`${moment(start).add(1, 'day').format('dddd Do')}`);
        break;
       case 'Tue':
        dates.push(`${moment(start).add(2, 'day').format('dddd Do')}`);
        break;
      case 'Wed':
        dates.push(`${moment(start).add(3, 'day').format('dddd Do')}`);
        break;
      case 'Thu':
        dates.push(`${moment(start).add(4, 'day').format('dddd Do')}`);
        break;
      case 'Fri':
        dates.push(`${moment(start).add(5, 'day').format('dddd Do')}`);
        break;
      case 'Sat':
        dates.push(`${moment(start).add(6, 'day').format('dddd Do')}`);
        break;
      default:
        dates.push('');
    }
  }
  return dates;
};

export default MeetingDates;
