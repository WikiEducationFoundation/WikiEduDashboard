import React from 'react';
import { mount } from 'enzyme';
import { Link, MemoryRouter, Route, Routes } from 'react-router-dom';
import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';

import Sidebar from '../../../app/assets/javascripts/components/tickets/sidebar.jsx';
import '../../testHelper';
import { Provider } from 'react-redux';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe('Tickets', () => {
  const store = mockStore({
    admins: []
  });
  const ticket = {
    project: {},
    owner: {},
    sender: {},
    status: 0
  };
  const props = {
    currentUser: {},
    ticket,
    createdAt: new Date(),
  };
  const MockProvider = (mockProps) => {
    return (
      <Provider store={store}>
        <MemoryRouter initialEntries={['/tickets/dashboard/5']}>
          <Routes>
            <Route
              path="/tickets/dashboard/:ticket_id"
              element={<Sidebar {...mockProps} />}
            />
          </Routes>
        </MemoryRouter>
      </Provider>
    );
  };
  const component = mount(<MockProvider {...props} />);
  describe('Sidebar', () => {
    it('should display the standard information', () => {
      expect(component.find('.sidebar .created-at').length).toBeTruthy;
      expect(component.find('.sidebar .status').length).toBeTruthy;
      expect(component.find('.sidebar .owner').length).toBeTruthy;

      expect(component.find('.sidebar .course-name').length).toBeTruthy;
      expect(component.find('.sidebar .course-name').text()).toEqual('Course Unknown');

      expect(component.find('.sidebar .related-tickets').length).toBeTruthy;
      expect(component.find('.sidebar .related-tickets').text()).toEqual('Search all tickets for: ');

      expect(component.find('.sidebar .user-record').length).toBeTruthy;
      expect(component.find('.sidebar .user-record').text()).toEqual('Unknown User Record');

      expect(component.find('.sidebar .button.info').length).toBeTruthy;
      expect(component.find('.sidebar .button.info').text()).toEqual('Email Ticket Owner');

      expect(component.find('.sidebar .button.danger').length).toBeTruthy;
      expect(component.find('.sidebar .button.danger').text()).toEqual('Delete Ticket');
    });
    it('should display the owner as "You" if the owner is the current user', () => {
      ticket.owner = { id: 1 };
      props.currentUser = { id: 1 };

      const sidebar = mount(<MockProvider {...props} />);
      const text = sidebar.find('.sidebar .owner').text();

      expect(text).toContain('You');

      ticket.owner = {};
      props.currentUser = {};
    });
    it('should display the course name if a course is given', () => {
      ticket.project = { id: 1, title: 'Title', slug: 'title-slug' };

      const courseName = mount(<MockProvider {...props} />).find('.sidebar .course-name');
      const link = courseName.children().first();
      expect(link.type()).toEqual(Link);

      const text = link.children().reduce((acc, el) => acc + el.text(), '');
      expect(text).toContain('Title');

      ticket.project = {};
    });
    it('should display the user name if a user is given', () => {
      ticket.sender = { id: 1, username: 'username' };

      const sidebar = mount(<MockProvider {...props} />);
      const text = sidebar.find('.sidebar .user-record').text();

      expect(text).toContain('username');

      ticket.sender = {};
    });
  });
});
