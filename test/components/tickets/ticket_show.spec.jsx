import React from 'react';
import { shallow } from 'enzyme';

import { MESSAGE_KIND_REPLY, TICKET_STATUS_OPEN } from '../../../app/assets/javascripts/constants/tickets';
import { TicketShow } from '../../../app/assets/javascripts/components/tickets/ticket_show';
import '../../testHelper';

describe('Tickets', () => {
  describe('TicketShow', () => {
    const currentUser = {};
    const message = {
      id: 1,
      content: '',
      details: {},
      sender: {},
      status: MESSAGE_KIND_REPLY
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

    const props = {
      currentUser,
      ticket
    };
    it('should display the standard information', () => {
      const show = shallow(<TicketShow {...props} />);

      const link = show.find('Link');
      expect(link.length).toBeTruthy;
      expect(link.children().text()).toContain('Ticketing Dashboard');

      const title = show.find('.title');
      expect(title.length).toBeTruthy;
      expect(title.text()).toContain('Ticket from Real Name');

      const reply = show.find('Reply');
      expect(reply.length).toBeTruthy;

      const newReplyForm = show.find('NewReplyForm');
      expect(newReplyForm.length).toBeTruthy;
    });

    it('can display multiple messages', () => {
      ticket.messages = ticket.messages.concat([
        { id: 2, content: 'Another message' }
      ]);
      const show = shallow(<TicketShow {...props} />);

      const reply = show.find('Reply');
      expect(reply.length).toEqual(2);
    });
  });
});
