import '../testHelper';
import MeetingDates from '../../app/assets/javascripts/utils/meetingsDates';

describe('MeetingDates', () => {
  test(
    'if correct input given, returns the array of formatted meeting dates',
    () => {
      const start = '2016-01-01';
      const meetingsString = '(Mon, Wed)';
      const dates = MeetingDates(start, meetingsString);
         expect(dates).toStrictEqual(["Monday (01/02)", "Wednesday (01/04)"]);
        }
      );

    test(
      'if incorrect input given, returns the empty array',
      () => {
        const start = '2016-01-01';
        const meetingsString = 'X';
        const dates = MeetingDates(start, meetingsString);
           expect(dates).toStrictEqual([]);
          }
        );
        });