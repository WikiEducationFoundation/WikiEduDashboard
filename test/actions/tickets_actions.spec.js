import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { fetchTicket } from '../../app/assets/javascripts/actions/tickets_actions';
import { RECEIVE_TICKET } from '../../app/assets/javascripts/constants/tickets';
import '../testHelper';

describe('tickets actions', () => {
  describe('#fetchTicket', () => {
    test('receives the fetched ticket, so the selected ticket and its index row both update', async () => {
      const store = configureMockStore([thunk])({});
      const ticket = { id: 7, status: 2, messages: [] };
      global.fetch = jest.fn().mockResolvedValue({ ok: true, json: () => Promise.resolve({ ticket }) });

      await store.dispatch(fetchTicket(7));

      expect(global.fetch.mock.calls[0][0]).toMatch(/\/td\/tickets\/7$/);
      expect(store.getActions()).toEqual([{ type: RECEIVE_TICKET, ticket }]);
    });
  });
});
