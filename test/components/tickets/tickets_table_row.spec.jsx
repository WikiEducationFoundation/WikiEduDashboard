import React from 'react';
import { shallow } from 'enzyme';
import { MemoryRouter } from 'react-router';
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
      expect(sender.length).to.be.ok;
      expect(sender.text()).to.eq('email@email.com');

      const subject = row.find('.subject');
      expect(subject.length).to.be.ok;
      expect(subject.text()).to.eq('');

      const course = row.find('.course');
      expect(course.length).to.be.ok;
      expect(course.text()).to.eq('Course Unknown');

      const status = row.find('.status');
      expect(status.length).to.be.ok;
      expect(status.text()).to.eq('Open');

      const owner = row.find('.owner');
      expect(owner.length).to.be.ok;
      expect(owner.text()).to.eq('');

      const actions = row.find('.actions');
      expect(actions.length).to.be.ok;
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
      expect(sender.length).to.be.ok;
      expect(sender.text()).to.eq(ticket.sender.username);

      const subject = row.find('.subject');
      expect(subject.length).to.be.ok;
      expect(subject.text()).to.eq(ticket.subject);

      const course = row.find('.course');
      expect(course.length).to.be.ok;

      const status = row.find('.status');
      expect(status.length).to.be.ok;
      expect(status.text()).to.eq('Open');

      const owner = row.find('.owner');
      expect(owner.length).to.be.ok;
      expect(owner.text()).to.eq(ticket.owner.username);

      const actions = row.find('.actions');
      expect(actions.length).to.be.ok;
    });
  });
});
