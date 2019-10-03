import React from 'react';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import { MemoryRouter } from 'react-router';
import configureMockStore from 'redux-mock-store';

import { TicketsHandler } from '../../../app/assets/javascripts/components/tickets/tickets_handler';
import '../../testHelper';

const mockStore = configureMockStore()({
  admins: [],
  tickets: {
    filters: {
      owners: [],
      statuses: []
    }
  }
});

describe('Tickets', () => {
  describe('TicketsHandler', () => {
    it('should display the standard information', () => {
      const filteredTickets = [
        { id: 1, owner: {}, project: {}, sender: {}, subject: 'Subject 1' },
        { id: 2, owner: {}, project: {}, sender: {}, subject: 'Subject 2' }
      ];
      const tickets = { all: filteredTickets, sort: {} };

      const fetchTickets = sinon.stub().resolves();
      const setInitialTicketFilters = sinon.stub().resolves();
      const props = {
        fetchTickets,
        filteredTickets,
        setInitialTicketFilters,
        tickets
      };
      const handler = mount(
        <Provider store={mockStore}>
          <MemoryRouter>
            <TicketsHandler {...props} />
          </MemoryRouter>
        </Provider>
      );

      const heading = handler.find('h1');
      expect(heading.length).toBeTruthy;
      expect(heading.text()).toEqual('Ticketing Dashboard');

      const ticketStatusesFilter = handler.find('TicketStatusesFilter');
      expect(ticketStatusesFilter.length).toBeTruthy;

      const ticketOwnersFilter = handler.find('TicketOwnersFilter');
      expect(ticketOwnersFilter.length).toBeTruthy;

      const html = handler.html();
      filteredTickets.forEach((ticket) => {
        expect(html).toContain(ticket.subject);
      });
    });
  });
});
