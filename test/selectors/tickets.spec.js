import { getFilteredTickets, getOpenNeedHelpTickets } from '../../app/assets/javascripts/selectors';
import '../testHelper';

describe('ticket selectors', () => {
  const ticket = (id, subject, status, ownerId) => ({ id, subject, status, owner: { id: ownerId } });
  const myHelp = ticket(1, 'NeedHelpAlert', 0, 10);
  const othersHelp = ticket(2, 'NeedHelpAlert', 0, 20);
  const resolvedHelp = ticket(3, 'NeedHelpAlert', 2, 10);
  const routine = ticket(4, 'A question', 0, 10);
  const state = {
    tickets: {
      all: [myHelp, othersHelp, resolvedHelp, routine],
      filters: { owners: [{ value: 10 }], statuses: [{ value: 0 }] }
    }
  };

  test('getOpenNeedHelpTickets ignores the filters and other tickets', () => {
    expect(getOpenNeedHelpTickets(state)).toEqual([myHelp, othersHelp]);
  });

  test('getFilteredTickets still applies the owner and status filters', () => {
    expect(getFilteredTickets(state)).toEqual([myHelp, routine]);
  });
});
