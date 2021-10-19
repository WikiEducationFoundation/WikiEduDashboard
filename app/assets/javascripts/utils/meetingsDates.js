import moment from 'moment';

// this method adds date to meetings

const MeetingDates = (start, meetingsString) => {
  const meetings = meetingsString.split('').slice(1, meetingsString.length - 1).join('').split(', ');
  const dates = [];
  for (let i = 0; i < meetings.length; i += 1) {
    switch (meetings[i]) {
      case 'Sun':
        dates.push(`Sunday (${moment(start).format('MM/DD')})`);
        break;
     case 'Mon':
        dates.push(`Monday (${moment(start).add(1, 'day').format('MM/DD')})`);
        break;
       case 'Tue':
        dates.push(`Tuesday (${moment(start).add(2, 'day').format('MM/DD')})`);
        break;
      case 'Wed':
        dates.push(`Wednesday (${moment(start).add(3, 'day').format('MM/DD')})`);
        break;
      case 'Thu':
        dates.push(`Thursday (${moment(start).add(4, 'day').format('MM/DD')})`);
        break;
      case 'Fri':
        dates.push(`Friday (${moment(start).add(5, 'day').format('MM/DD')})`);
        break;
      case 'Sat':
        dates.push(`Saturday (${moment(start).add(6, 'day').format('MM/DD')})`);
        break;
      default:
        return [];
    }
  }
  return dates;
};

export default MeetingDates;
