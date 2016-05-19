import '../../testHelper';
const React = require('react');
const ReactTestUtils = require('react-addons-test-utils');
const GetHelpButton = require('../../../app/assets/javascripts/components/common/get_help_button.jsx').default;

GetHelpButton.__Rewire__('UserStore', {
  getFiltered: (args) => {
    if (JSON.stringify(args) === JSON.stringify({ content_expert: true })) {
      return [{ email: 'expert@wikiedu.org', username: 'Wiki Expert' }];
    }

    if (JSON.stringify(args) === JSON.stringify({ program_manager: true })) {
      return [{ email: 'manager@wikiedu.org', username: 'Wiki Manager' }];
    }
  }
});

describe('GetHelpButton', () => {
  describe('Content', () => {
    const currentUser = { role: 1 };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <GetHelpButton current_user={currentUser} />
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
      <GetHelpButton current_user={currentUser} />
    );

    const popContainer = ReactTestUtils.findRenderedDOMComponentWithClass(TestGetHelpButton, 'pop__container');

    it('should be collapsed by default', () => {
      const pop = popContainer.querySelectorAll('.pop')[0];
      expect(pop.classList.contains('open')).to.eq(false);
    });

    it('should open when clicked', () => {
      // const pop = popContainer.querySelectorAll('.pop')[0];
      // const getHelpButton = popContainer.querySelectorAll('button.small')[0];
      // expect(ReactTestUtils.isDOMComponent(getHelpButton)).to.eq(true);
      // ReactTestUtils.Simulate.click(getHelpButton);
      // expect(pop.classList.contains('open')).to.eq(true);
    });
  });

  describe('As an instructor', () => {
    const currentUser = { role: 1 };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <GetHelpButton current_user={currentUser} />
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
      <GetHelpButton current_user={currentUser} />
    );

    const popContainer = ReactTestUtils.findRenderedDOMComponentWithClass(TestGetHelpButton, 'pop__container');

    it('only lists the content expert', () => {
      const contentExperts = popContainer.querySelectorAll('.content-experts');
      expect(contentExperts[0].textContent).to.eq('Wiki Expert (Content Expert)');
      expect(popContainer.querySelectorAll('.program-managers').length).to.eq(0);
    });
  });
});
