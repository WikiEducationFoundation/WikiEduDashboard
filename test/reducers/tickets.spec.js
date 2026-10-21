import deepFreeze from 'deep-freeze';
import tickets from '../../app/assets/javascripts/reducers/tickets';
import {
  DELETE_TICKET,
  MESSAGE_KIND_NOTE_DELETE,
  RECEIVE_TICKET,
  SET_MESSAGES_TO_READ,
  UPDATE_TICKET
} from '../../app/assets/javascripts/constants/tickets';
import '../testHelper';

describe('tickets reducer', () => {
  const initialState = tickets(undefined, { type: null });
  const ticket = id => ({ id, status: 0, messages: [{ id: id * 10, read: false }] });
  const loadedState = (...list) => deepFreeze({ ...initialState, all: list, loading: false });

  test('starts with an empty list that is still loading', () => {
    expect(initialState.all).toEqual([]);
    expect(initialState.loading).toBe(true);
  });

  describe('RECEIVE_TICKET', () => {
    test('selects the ticket and refreshes its row in the list', () => {
      const resolved = { ...ticket(2), status: 2 };
      const state = tickets(loadedState(ticket(1), ticket(2)), { type: RECEIVE_TICKET, ticket: resolved });
      expect(state.selected).toEqual(resolved);
      expect(state.all).toEqual([ticket(1), resolved]);
    });

    test('selects the ticket without adding it to an unfetched list', () => {
      const state = tickets(deepFreeze(initialState), { type: RECEIVE_TICKET, ticket: ticket(1) });
      expect(state.selected).toEqual(ticket(1));
      expect(state.all).toEqual([]);
      expect(state.loading).toBe(true);
    });
  });

  describe('SET_MESSAGES_TO_READ', () => {
    test('replaces the matching ticket in the list', () => {
      const readTicket = { ...ticket(2), messages: [{ id: 20, read: true }] };
      const state = tickets(loadedState(ticket(1), ticket(2)), {
        type: SET_MESSAGES_TO_READ, data: { ticket: readTicket }
      });
      expect(state.all).toEqual([ticket(1), readTicket]);
      expect(state.selected).toEqual(readTicket);
    });

    test('does not add the ticket to an empty, still-loading list', () => {
      // Landing directly on a ticket page marks its messages read before the
      // index has ever been fetched. Inserting the ticket here would make
      // TicketsHandler think the list is loaded and leave it spinning.
      const state = tickets(deepFreeze(initialState), {
        type: SET_MESSAGES_TO_READ, data: { ticket: ticket(1) }
      });
      expect(state.all).toEqual([]);
      expect(state.loading).toBe(true);
    });
  });

  describe('UPDATE_TICKET', () => {
    test('replaces the matching ticket in the list', () => {
      const updated = { ...ticket(2), status: 2 };
      const state = tickets(loadedState(ticket(1), ticket(2), ticket(3)), {
        type: UPDATE_TICKET, id: 2, data: { ticket: updated }
      });
      expect(state.all).toEqual([ticket(1), updated, ticket(3)]);
    });

    test('leaves the list unchanged when the ticket is not in it', () => {
      const state = tickets(loadedState(ticket(1), ticket(2), ticket(3)), {
        type: UPDATE_TICKET, id: 99, data: { ticket: ticket(99) }
      });
      expect(state.all.map(t => t.id)).toEqual([1, 2, 3]);
    });

    test('updates the selected ticket even when it is not in the list', () => {
      const updated = { ...ticket(1), status: 2 };
      const state = tickets(deepFreeze({ ...initialState, selected: ticket(1) }), {
        type: UPDATE_TICKET, id: 1, data: { ticket: updated }
      });
      expect(state.selected).toEqual(updated);
      expect(state.all).toEqual([]);
    });

    test('leaves the selected ticket alone when a different ticket is updated', () => {
      const state = tickets(deepFreeze({ ...loadedState(ticket(1), ticket(2)), selected: ticket(1) }), {
        type: UPDATE_TICKET, id: 2, data: { ticket: { ...ticket(2), status: 2 } }
      });
      expect(state.selected).toEqual(ticket(1));
    });
  });

  describe('DELETE_TICKET', () => {
    test('removes the ticket from the list', () => {
      const state = tickets(loadedState(ticket(1), ticket(2), ticket(3)), { type: DELETE_TICKET, id: 2 });
      expect(state.all.map(t => t.id)).toEqual([1, 3]);
    });

    test('leaves the list unchanged when the ticket is not in it', () => {
      const state = tickets(loadedState(ticket(1), ticket(2)), { type: DELETE_TICKET, id: 99 });
      expect(state.all.map(t => t.id)).toEqual([1, 2]);
    });
  });

  describe('MESSAGE_KIND_NOTE_DELETE', () => {
    const selected = { id: 1, status: 0, messages: [{ id: 10 }, { id: 11 }, { id: 12 }] };

    test('removes the note from the selected ticket without mutating the old state', () => {
      const previous = deepFreeze({ ...initialState, selected });
      const state = tickets(previous, { type: MESSAGE_KIND_NOTE_DELETE, id: 11 });
      expect(state.selected.messages.map(m => m.id)).toEqual([10, 12]);
      expect(previous.selected.messages.map(m => m.id)).toEqual([10, 11, 12]);
    });

    test('keeps the ticket list as a list of tickets', () => {
      const state = tickets(deepFreeze({ ...loadedState(ticket(1), ticket(2)), selected }), {
        type: MESSAGE_KIND_NOTE_DELETE, id: 11
      });
      expect(state.all.map(t => t.id)).toEqual([1, 2]);
      expect(state.all[0].messages.map(m => m.id)).toEqual([10, 12]);
    });

    test('does not add the selected ticket to an empty list', () => {
      const state = tickets(deepFreeze({ ...initialState, selected }), {
        type: MESSAGE_KIND_NOTE_DELETE, id: 11
      });
      expect(state.all).toEqual([]);
      expect(state.loading).toBe(true);
    });
  });
});
