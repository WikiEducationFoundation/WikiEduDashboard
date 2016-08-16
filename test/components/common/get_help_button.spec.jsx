import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import GetHelpButton from '../../../app/assets/javascripts/components/common/get_help_button.jsx';

GetHelpButton.__Rewire__('UserStore', {
  getFiltered: (args) => {
    if (JSON.stringify(args) === JSON.stringify({ content_expert: true, role: 4 })) {
      return [{ email: 'expert@wikiedu.org', username: 'Wiki Expert' }];
    }

    if (JSON.stringify(args) === JSON.stringify({ program_manager: true, role: 4 })) {
      return [{ email: 'manager@wikiedu.org', username: 'Wiki Manager' }];
    }
  }
});

describe('GetHelpButton', () => {
  describe('Content', () => {
    const currentUser = { role: 1 };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <GetHelpButton current_user={currentUser} key="get_help" />
    );

    const popContainer = ReactTestUtils.findRenderedDOMComponentWithClass(TestGetHelpButton, 'pop__container');

    it('renders the get help button', () => {
      const getHelpButton = popContainer.querySelectorAll('button.small');
      expect(getHelpButton.length).to.eq(1);
      expect(getHelpButton[0].textContent).to.eq('Get Help');
    });

    it('has an ask search field', () => {
      const searchField = popContainer.querySelectorAll('input[type=text]');
      expect(searchField.length).to.eq(1);
      expect(searchField[0].getAttribute('placeholder')).to.eq('Search Help Forum');
    });
  });

  describe('Interactions', () => {
    const currentUser = { role: 1 };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <GetHelpButton current_user={currentUser} key="get_help" />
    );

    const popContainer = ReactTestUtils.findRenderedDOMComponentWithClass(TestGetHelpButton, 'pop__container');

    it('should be collapsed by default', () => {
      const pop = popContainer.querySelectorAll('.pop')[0];
      expect(pop.classList.contains('open')).to.eq(false);
    });

    it('should open when clicked', (done) => {
      const pop = popContainer.querySelectorAll('.pop')[0];
      const getHelpButton = popContainer.querySelectorAll('button.small')[0];
      expect(ReactTestUtils.isDOMComponent(getHelpButton)).to.eq(true);
      ReactTestUtils.Simulate.click(getHelpButton);
      setImmediate(() => {
        expect(pop.classList.contains('open')).to.eq(true);
        done();
      });
    });

    it('should switch to form', (done) => {
      const expertLink = popContainer.querySelectorAll('.content-expert-link')[0];
      expect(ReactTestUtils.isDOMComponent(expertLink)).to.eq(true);
      ReactTestUtils.Simulate.click(expertLink);
      setImmediate(() => {
        expect(popContainer.querySelectorAll('.get-help-info').length).to.eq(0);
        expect(popContainer.querySelectorAll('.get-help-form').length).to.eq(1);
        done();
      });
    });
  });

  describe('As an instructor', () => {
    const currentUser = { role: 1 };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <GetHelpButton current_user={currentUser} key="get_help" />
    );

    const popContainer = ReactTestUtils.findRenderedDOMComponentWithClass(TestGetHelpButton, 'pop__container');

    it('lists the both program manager and content expert', () => {
      const contentExperts = popContainer.querySelectorAll('.content-experts');
      const programManagers = popContainer.querySelectorAll('.program-managers');
      expect(contentExperts[0].textContent).to.eq('Wiki Expert (Content Expert)');
      expect(programManagers[0].textContent).to.eq('Wiki Manager (Program Manager)');
    });
  });

  describe('As a student', () => {
    const currentUser = { role: 0 };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <GetHelpButton current_user={currentUser} key="get_help" />
    );

    const popContainer = ReactTestUtils.findRenderedDOMComponentWithClass(TestGetHelpButton, 'pop__container');

    it('only lists the content expert', () => {
      const contentExperts = popContainer.querySelectorAll('.content-experts');
      expect(contentExperts[0].textContent).to.eq('Wiki Expert (Content Expert)');
      expect(popContainer.querySelectorAll('.program-managers').length).to.eq(0);
    });
  });
});
