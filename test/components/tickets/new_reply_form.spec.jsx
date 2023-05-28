import React from 'react';
import { mount } from 'enzyme';

import { INSTRUCTOR_ROLE } from '../../../app/assets/javascripts/constants/user_roles';
import {
  MESSAGE_KIND_NOTE,
  MESSAGE_KIND_REPLY,
  TICKET_STATUS_AWAITING_RESPONSE,
  TICKET_STATUS_OPEN,
  TICKET_STATUS_RESOLVED
} from '../../../app/assets/javascripts/constants/tickets';
import NewReplyForm from '../../../app/assets/javascripts/components/tickets/new_reply_form';
import '../../testHelper';
import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import {
  createReply,
  fetchTicket,
} from '@actions/tickets_actions';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);
jest.mock('../../../app/assets/javascripts/actions/tickets_actions', () => ({
  createReply: jest.fn(),
  fetchTicket: jest.fn(),

}));
describe('Tickets', () => {
  describe('NewReplyForm', () => {
    const message = {};
    const ticket = {
      id: 1,
      messages: [message],
      project: {},
      owner: {},
      sender: {
        real_name: 'Real Name'
      },
      status: TICKET_STATUS_OPEN
    };
    const mockDispatchFn = jest.fn(() => Promise.resolve());

    const props = {
      currentUser: {
        id: 1
      },
      ticket,
      dispatch: mockDispatchFn
    };
    const store = mockStore({ validations: { validations: { key: 2 } } });
    const MockProvider = (mockProps) => {
      return (
        <Provider store={store}>
          <NewReplyForm {...mockProps} />
        </Provider >
      );
    };
    const form = mount(<MockProvider {...props} />);



    it('should render correctly with the standard information', () => {
      expect(form.length).toBeTruthy;
      expect(form.find('[title="Show BCC"]').length).toBeTruthy;
      expect(form.find('#bcc').length).toBeTruthy;
      expect(form.find('#cc').length).toBeFalsy;

      expect(form.find('#content').length).toBeTruthy;

      expect(form.find('#reply-resolve').length).toBeTruthy;
      expect(form.find('#reply').length).toBeTruthy;
      expect(form.find('#create-note').length).toBeTruthy;
    });
    it('does not create a new reply if there is no content', async () => {
      await form.find('#reply-resolve').simulate('click', { preventDefault: () => { } });
      expect(createReply).not.toHaveBeenCalled();
      expect(fetchTicket).not.toHaveBeenCalled();
    });
    it('should toggle CC field when clicked on Show BCC button', () => {
      const bccButton = form.find('button[title="Show BCC"]');
      expect(form.find('#cc').length).toBe(0); // initial condition
      bccButton.simulate('click');
      expect(form.find('#cc').length).toBe(5); // after click event
    });
  });
});
