import React from 'react';
import { mount, shallow } from 'enzyme';

import { INSTRUCTOR_ROLE } from '../../../app/assets/javascripts/constants/user_roles';
import {
  MESSAGE_KIND_NOTE,
  MESSAGE_KIND_REPLY,
  TICKET_STATUS_AWAITING_RESPONSE,
  TICKET_STATUS_OPEN,
  TICKET_STATUS_RESOLVED
} from '../../../app/assets/javascripts/constants/tickets';
import { NewReplyForm } from '../../../app/assets/javascripts/components/tickets/new_reply_form';
import '../../testHelper';
import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

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
    const createReplyFn = jest.fn(() => Promise.resolve());
    const fetchTicketFn = jest.fn(() => Promise.resolve());
    const mockDispatchFn = jest.fn(() => Promise.resolve());

    const props = {
      currentUser: {
        id: 1
      },
      ticket,
      fetchTicket: fetchTicketFn,
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
    const form = mount(<MockProvider {...props} />).find('.tickets-reply');

    afterEach(() => {
      form.setState({
        cc: '',
        content: '',
        plainText: '',
        sending: false,
        showCC: false,
        bccToSalesforce: false
      });
    });

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
    it('should set BCC to true if the sender is an instructor', () => {
      const instructorProps = {
        ...props,
        ticket: {
          ...ticket,
          sender: {
            role: INSTRUCTOR_ROLE
          }
        }
      };
      const instructorForm = shallow(<NewReplyForm {...instructorProps} />);

      expect(instructorForm.state().bccToSalesforce).toBeTruthy;
      const bcc = instructorForm.find('#bcc');
      expect(bcc.props().checked).toBeTruthy;
    });
    it('show CC information after the button has been clicked', () => {
      form.instance().setState({ showCC: true });
      expect(form.find('#cc').length).toBeTruthy;
    });
    it('does not create a new reply if there is no content', async () => {
      await form.find('#reply-resolve').simulate('click', { preventDefault: () => { } });
      expect(createReplyFn).not.toHaveBeenCalled();
      expect(fetchTicketFn).not.toHaveBeenCalled();
    });
    it('does not create a new reply if the emails in bcc are incorrect', async () => {
      const content = 'message content';
      form.instance().setState({
        content: content,
        plainText: content,
        cc: 'failure'
      });

      await form.find('#reply-resolve').simulate('click', { preventDefault: () => { } });
      expect(createReplyFn).not.toHaveBeenCalled();
      expect(fetchTicketFn).not.toHaveBeenCalled();

      form.instance().setState({
        content: content,
        plainText: content,
        cc: 'correct@email.com, failure'
      });

      await form.find('#reply-resolve').simulate('click', { preventDefault: () => { } });
      expect(createReplyFn).not.toHaveBeenCalled();
      expect(fetchTicketFn).not.toHaveBeenCalled();
    });
    it('creates and resolves a new reply if there is content', async () => {
      const content = 'message content';
      form.instance().setState({
        content: content,
        plainText: content
      });
      await form.find('#reply-resolve').simulate('click', { preventDefault: () => { } });

      const body = {
        content,
        kind: MESSAGE_KIND_REPLY,
        read: true,
        sender_id: props.currentUser.id,
        ticket_id: ticket.id
      };

      expect(createReplyFn).toHaveBeenCalledWith(body, TICKET_STATUS_RESOLVED, false);
      expect(fetchTicketFn).toHaveBeenCalledWith(ticket.id);
    });
    it('creates a new reply if there is content', async () => {
      const content = 'message content';
      form.instance().setState({
        content: content,
        plainText: content
      });
      await form.find('#reply').simulate('click', { preventDefault: () => { } });

      const body = {
        content,
        kind: MESSAGE_KIND_REPLY,
        read: true,
        sender_id: props.currentUser.id,
        ticket_id: ticket.id
      };

      expect(createReplyFn).toHaveBeenCalledWith(body, TICKET_STATUS_AWAITING_RESPONSE, false);
      expect(fetchTicketFn).toHaveBeenCalledWith(ticket.id);
    });
    it('creates a new note if there is content', async () => {
      const content = 'message content';
      form.instance().setState({
        content: content,
        plainText: content
      });
      await form.find('#create-note').simulate('click', { preventDefault: () => { } });

      const body = {
        content,
        kind: MESSAGE_KIND_NOTE,
        read: true,
        sender_id: props.currentUser.id,
        ticket_id: ticket.id
      };
      expect(createReplyFn).toHaveBeenCalledWith(body, ticket.status, false);
      expect(fetchTicketFn).toHaveBeenCalledWith(ticket.id);
    });
  });
});
