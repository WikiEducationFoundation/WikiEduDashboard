import React from 'react';
import { shallow } from 'enzyme';
import { Link } from 'react-router-dom';

import { Sidebar } from '../../../app/assets/javascripts/components/tickets/sidebar.jsx';
import '../../testHelper';

describe('Tickets:Sidebar', () => {
  describe('rendering', () => {
    const ticket = {
      project: {},
      owner: {},
      sender: {},
      status: 0
    };
    const props = {
      currentUser: {},
      ticket
    };
    const component = shallow(<Sidebar {...props} />);

    it('should display the standard information', () => {
      expect(component.find('.sidebar .created-at').length).to.be.ok;
      expect(component.find('.sidebar .status').length).to.be.ok;
      expect(component.find('.sidebar .owner').length).to.be.ok;

      expect(component.find('.sidebar .course-name').length).to.be.ok;
      expect(component.find('.sidebar .course-name').text()).to.equal('Course Unknown');

      expect(component.find('.sidebar .user-record').length).to.be.ok;
      expect(component.find('.sidebar .user-record').text()).to.equal('Unknown User Record');

      expect(component.find('.sidebar .button.info').length).to.be.ok;
      expect(component.find('.sidebar .button.info').text()).to.equal('Email Ticket Owner');

      expect(component.find('.sidebar .button.danger').length).to.be.ok;
      expect(component.find('.sidebar .button.danger').text()).to.equal('Delete Ticket');
    });
    it('should display the owner as "You" if the owner is the current user', () => {
      ticket.owner = { id: 1 };
      props.currentUser = { id: 1 };

      const sidebar = shallow(<Sidebar {...props} />);
      const text = sidebar.find('.sidebar .owner').text();

      expect(text).to.include('You');

      ticket.owner = {};
      props.currentUser = {};
    });
    it('should display the course name if a course is given', () => {
      ticket.project = { id: 1, title: 'Title', slug: 'title-slug' };

      const courseName = shallow(<Sidebar {...props} />).find('.sidebar .course-name');
      const link = courseName.children().first();
      expect(link.type()).to.eq(Link);

      const text = link.children().reduce((acc, el) => acc + el.text(), '');
      expect(text).to.include('Title');

      ticket.project = {};
    });
    it('should display the user name if a user is given', () => {
      ticket.sender = { id: 1, username: 'username' };

      const sidebar = shallow(<Sidebar {...props} />);
      const text = sidebar.find('.sidebar .user-record').text();

      expect(text).to.include('username');

      ticket.sender = {};
    });
  });
});
