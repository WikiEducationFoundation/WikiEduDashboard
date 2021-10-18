import moment from 'moment';

// this method adds date to meetings

const MeetingDates = (start, meetingsString) => {
  const meetings = meetingsString.split('').slice(1, meetingsString.length - 1).join('').split(', ');
  const dates = [];
  for (let i = 0; i < meetings.length; i += 1) {
    switch (meetings[i]) {
      case 'Sun':
        dates.push(`${meetings[i]} - ${moment(start).format('MM/DD')}`);
        break;
     case 'Mon':
        dates.push(`${meetings[i]} - ${moment(start).add(1, 'day').format('MM/DD')}`);
        break;
       case 'Tue':
        dates.push(`${meetings[i]} - ${moment(start).add(2, 'day').format('MM/DD')}`);
        break;
      case 'Wed':
        dates.push(`${meetings[i]} - ${moment(start).add(3, 'day').format('MM/DD')}`);
        break;
      case 'Thu':
        dates.push(`${meetings[i]} - ${moment(start).add(4, 'day').format('MM/DD')}`);
        break;
      case 'Fri':
        dates.push(`${meetings[i]} - ${moment(start).add(5, 'day').format('MM/DD')}`);
        break;
      case 'Sat':
        dates.push(`${meetings[i]} - ${moment(start).add(6, 'day').format('MM/DD')}`);
        break;
      default:
        dates.push('');
    }
  }
  return dates;
};

export default MeetingDates;
