import '../testHelper';
import moment from 'moment';
import { dateSegments } from '../../app/assets/javascripts/actions/tickets_actions';

describe('Ticket Actions', () => {
  describe('#dateSegments', () => {
    it('creates four dates evenly spaced apart', () => {
      const date = moment('06-30-2000', 'MM-DD-YYYY');
      const actual = dateSegments(date);
      const expected = ['2000-06-30', '2000-06-15', '2000-05-31', '2000-05-16', '2000-05-01'];
      expect(actual).to.deep.eq(expected);
    });
  });
});
