import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { fetchTicket, fetchTickets } from '../../app/assets/javascripts/actions/tickets_actions';
import { FETCH_TICKETS, RECEIVE_TICKET, RECEIVE_TICKETS } from '../../app/assets/javascripts/constants/tickets';
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

  describe('#fetchTickets', () => {
    test('drops batches from a fetch that a newer one has superseded', async () => {
      const store = configureMockStore([thunk])({});
      const staleTicket = { id: 1, updated_at: '2026-01-01' };
      const searchTicket = { id: 2, updated_at: '2026-01-02' };
      let releaseStale;
      const staleResponse = new Promise((resolve) => { releaseStale = resolve; });
      global.fetch = jest.fn((url) => {
        if (url.includes('/tickets/search')) {
          return Promise.resolve({ ok: true, json: () => Promise.resolve({ tickets: [searchTicket] }) });
        }
        return staleResponse;
      });

      const initialLoad = store.dispatch(fetchTickets());
      // Let the initial load's first batch request go out before the search starts.
      await new Promise(resolve => setTimeout(resolve, 0));
      const search = store.dispatch(fetchTickets({ in_subject: 'subject' }));
      await search;
      releaseStale({ ok: true, json: () => Promise.resolve({ tickets: [staleTicket] }) });
      await initialLoad;

      const received = store.getActions().filter(action => action.type === RECEIVE_TICKETS);
      expect(store.getActions()[0]).toEqual({ type: FETCH_TICKETS });
      expect(received).toHaveLength(10);
      received.forEach(action => expect(action.data).toEqual([searchTicket]));
      // The superseded fetch stops after its in-flight batch instead of requesting the rest.
      expect(global.fetch.mock.calls.filter(([url]) => url.includes('/td/tickets'))).toHaveLength(1);
    });
  });
});
