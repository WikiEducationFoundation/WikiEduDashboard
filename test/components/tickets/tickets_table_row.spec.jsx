import React from 'react';
import { shallow } from 'enzyme';
import { TICKET_STATUS_OPEN } from '../../../app/assets/javascripts/constants/tickets';
import { TicketsTableRow } from '../../../app/assets/javascripts/components/tickets/tickets_table_row';
import '../../testHelper';

describe('Tickets', () => {
  describe('TicketsTableRow', () => {
    it('should display the standard information', () => {
      const ticket = {
        id: 1,
        owner: {},
        project: {},
        sender: {},
        sender_email: 'email@email.com',
        status: TICKET_STATUS_OPEN
      };
      const row = shallow(<TicketsTableRow ticket={ticket} />);

      const sender = row.find('.sender');
      expect(sender.length).toBeTruthy;
      expect(sender.text()).toEqual('email@email.com');

      const subject = row.find('.subject');
      expect(subject.length).toBeTruthy;
      expect(subject.text()).toEqual('');

      const course = row.find('.course-page');
      expect(course.length).toBeTruthy;
      expect(course.text()).toEqual('Course Unknown');

      const status = row.find('.status');
      expect(status.length).toBeTruthy;
      expect(status.text()).toEqual('Open');

      const owner = row.find('.owner');
      expect(owner.length).toBeTruthy;
      expect(owner.text()).toEqual('');

      const actions = row.find('.actions');
      expect(actions.length).toBeTruthy;
    });
    it('should display full information when set', () => {
      const ticket = {
        id: 1,
        owner: {
          username: 'Owner Username'
        },
        project: {
          id: 1,
          title: 'Project Title'
        },
        sender: {
          username: 'Sender Username'
        },
        sender_email: 'email@email.com',
        status: TICKET_STATUS_OPEN,
        subject: 'My Subject'
      };
      const row = shallow(<TicketsTableRow ticket={ticket} />);

      const sender = row.find('.sender');
      expect(sender.length).toBeTruthy;
      expect(sender.text()).toEqual(ticket.sender.username);

      const subject = row.find('.subject');
      expect(subject.length).toBeTruthy;
      expect(subject.text()).toEqual(ticket.subject);

      const course = row.find('.course-page');
      expect(course.length).toBeTruthy;

      const status = row.find('.status');
      expect(status.length).toBeTruthy;
      expect(status.text()).toEqual('Open');

      const owner = row.find('.owner');
      expect(owner.length).toBeTruthy;
      expect(owner.text()).toEqual(ticket.owner.username);

      const actions = row.find('.actions');
      expect(actions.length).toBeTruthy;
    });
  });
});
