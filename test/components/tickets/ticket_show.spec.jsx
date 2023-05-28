import React from 'react';
import { mount } from 'enzyme';

import { MESSAGE_KIND_REPLY, TICKET_STATUS_OPEN } from '../../../app/assets/javascripts/constants/tickets';
import { TicketShow } from '../../../app/assets/javascripts/components/tickets/ticket_show';
import configureMockStore from 'redux-mock-store';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import {
  deleteTicket,
  notifyOfMessage,
} from '@actions/tickets_actions';
import '../../testHelper';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

jest.mock('../../../app/assets/javascripts/actions/tickets_actions', () => ({
  deleteTicket: jest.fn(),
  notifyOfMessage: jest.fn(),
}));

describe('Tickets', () => {
  describe('TicketShow', () => {
    const message = {
      id: 1,
      content: '',
      details: { delivered: false },
      sender: {},
      status: MESSAGE_KIND_REPLY,
      created_at: new Date()
    };
    const ticket = {
      id: 1,
      messages: [message],
      owner: {},
      project: {},
      sender: {
        real_name: 'Real Name'
      },
      status: TICKET_STATUS_OPEN
    };
    const store = mockStore({ validations: { validations: { key: 2 } }, currentUserFromHtml: {}, admins: [], messages: [], ticket: ticket });
    const MockProvider = (mockProps) => {
      return (
        <Provider store={store}>
          <MemoryRouter initialEntries={['/tickets/dashboard/5']}>
            <Routes>
              <Route
                path="/tickets/dashboard/:ticket_id"
                element={<TicketShow {...mockProps} />}
              />
            </Routes>
          </MemoryRouter>
        </Provider>
      );
    };
    const props = {
      deleteTicket,
      notifyOfMessage,
      ticket,
    };
    it('should display the standard information', () => {
      const show = mount(<MockProvider {...props} />);

      const link = show.find('Link').first();
      expect(link.length).toBeTruthy();
      expect(link.children().text()).toContain('Ticketing Dashboard');

      const title = show.find('.title');
      expect(title.length).toBeTruthy();
      expect(title.text()).toContain('Ticket from Real Name');

      const reply = show.find('Reply');
      expect(reply.length).toBeTruthy();

      const newReplyForm = show.find('NewReplyForm');
      expect(newReplyForm.length).toBeTruthy();
    });

    it('can display multiple messages', () => {
      ticket.messages = ticket.messages.concat([
        {
          id: 2,
          content: 'Just another message',
          details: { delivered: false },
          sender: {},
          status: MESSAGE_KIND_REPLY,
          created_at: new Date()
        }
      ]);
      const show = mount(<MockProvider {...props} />);

      const reply = show.find('Reply');
      expect(reply.length).toEqual(2);
    });
  });
});
