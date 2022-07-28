import React from 'react';
import { shallow } from 'enzyme';
import { subDays } from 'date-fns';
import { MESSAGE_KIND_REPLY, MESSAGE_KIND_NOTE } from '../../../app/assets/javascripts/constants/tickets';
import { Reply } from '../../../app/assets/javascripts/components/tickets/reply.jsx';
import '../../testHelper';

describe('Tickets', () => {
  describe('Reply', () => {
    const message = {
      content: 'Lorem ipsum dolor sit amet consectetur adipisicing elit.',
      details: {
        delivered: new Date(),
        sender_email: 'sender@email.com',
        subject: 'My Subject',
        delivery_failed: subDays(new Date(), 7)
      },
      kind: MESSAGE_KIND_REPLY,
      sender: {},
      created_at: new Date()
    };
    const reply = shallow(<Reply message={message} />);
    it('displays all the standard information', () => {
      const subject = reply.find('.subject');
      expect(subject.text()).toEqual(message.details.subject);

      const cc = reply.find('.cc');
      expect(cc.length).toBeFalsy;

      const content = reply.find('.message-body');
      expect(content.html()).toContain(message.content);

      const from = reply.find('.from');
      expect(from.text()).toContain(message.details.sender_email);

      expect(reply.find('.created-at').length).toBeTruthy;
      expect(reply.find('[imageName="check"]').length).toBeTruthy;
    });
    it('displays the subject as NOTE if the message is a note', () => {
      const noteMessage = {
        ...message,
        details: {
          ...message.details,
          subject: null
        },
        kind: MESSAGE_KIND_NOTE
      };
      const note = shallow(<Reply message={noteMessage} />);
      const subject = note.find('.subject');
      expect(subject.text()).toEqual('NOTE');
    });
    it('should include CC information if it is included', () => {
      const email = 'email@email.com';
      const messageWithCC = {
        ...message,
        details: {
          ...message.details,
          cc: [{ email }]
        }
      };
      const replyWithCC = shallow(<Reply message={messageWithCC} />);
      expect(replyWithCC.text()).toContain(email);
    });
    it('should set content as HTML', () => {
      const content = '<p>Message</p><p>Content</p>';
      const messageWithHTMLContent = {
        ...message,
        content
      };
      const replyWithHTMLContent = shallow(<Reply message={messageWithHTMLContent} />);
      const contentElement = replyWithHTMLContent.find('.message-body');
      expect(contentElement.html()).toContain(content);
    });
    it('should include the sender\'s real name if possible', () => {
      const name = 'Real Name';
      const username = 'username';
      const messageWithSenderName = {
        ...message,
        sender: {
          real_name: name,
          username
        }
      };
      const replyWithRealName = shallow(<Reply message={messageWithSenderName} />);
      const from = replyWithRealName.find('.from');
      expect(from.text()).toContain(name);
    });
    it('should include the sender\'s username as a backup', () => {
      const username = 'username';
      const messageWithSenderName = {
        ...message,
        sender: {
          real_name: null,
          username
        }
      };
      const replyWithRealName = shallow(<Reply message={messageWithSenderName} />);
      const from = replyWithRealName.find('.from');
      expect(from.text()).toContain(username);
    });
    it('should include an error icon if the message could not be delivered', () => {
      const messageWithError = {
        ...message,
        details: {
          ...message.details,
          delivery_failed: new Date()
        }
      };
      const replyWithError = shallow(<Reply message={messageWithError} />);
      const icon = replyWithError.find('[imageName="minus"]');
      expect(icon.length).toBeTruthy;
    });
  });
});
