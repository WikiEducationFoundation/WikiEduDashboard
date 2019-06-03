import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import { createStore, applyMiddleware, compose } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';

import reducer from '../../../app/assets/javascripts/reducers';
import '../../testHelper';
import GetHelpButton from '../../../app/assets/javascripts/components/common/get_help_button.jsx';

const users = [
  { email: 'expert@wikiedu.org', username: 'Wiki Expert', context_expert: true, role: 4 },
  { email: 'manager@wikiedu.org', username: 'Wiki Manager', program_manager: true, role: 4 }
];
const course = { type: 'ClassroomProgramCourse' };
const initialState = { users: { users } };
const reduxStoreWithUsers = createStore(reducer, initialState, compose(applyMiddleware(thunk)));

describe('GetHelpButton', () => {
  describe('Content', () => {
    const currentUser = { isAdvancedRole: 1 };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStoreWithUsers}>
        <GetHelpButton currentUser={currentUser} key="get_help" course={course} />
      </Provider>
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
    const currentUser = { isAdvancedRole: 1 };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStoreWithUsers}>
        <GetHelpButton currentUser={currentUser} key="get_help" course={course} />
      </Provider>
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
      const expertLink = popContainer.querySelectorAll('.wikipedia-help-link')[0];
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
    const currentUser = { isAdvancedRole: true };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStoreWithUsers}>
        <GetHelpButton currentUser={currentUser} key="get_help" course={course} />
      </Provider>
    );

    const popContainer = ReactTestUtils.findRenderedDOMComponentWithClass(TestGetHelpButton, 'pop__container');

    it('lists the both wikipedia help and program help', () => {
      const wikipediaHelp = popContainer.querySelector('.contact-wikipedia-help');
      const programHelp = popContainer.querySelector('.contact-program-help');
      expect(wikipediaHelp.textContent).to.eq('question about editing Wikipedia');
      expect(programHelp.textContent).to.eq('question about Wiki Ed or your assignment');
    });
  });

  describe('As a student', () => {
    const currentUser = { isStudent: true };

    const TestGetHelpButton = ReactTestUtils.renderIntoDocument(
      <Provider store={reduxStoreWithUsers}>
        <GetHelpButton currentUser={currentUser} key="get_help" course={course} />
      </Provider>
    );

    const popContainer = ReactTestUtils.findRenderedDOMComponentWithClass(TestGetHelpButton, 'pop__container');

    it('only lists the content expert', () => {
      const contentExperts = popContainer.querySelector('.contact-wikipedia-help');
      expect(contentExperts.textContent).to.eq('question about editing Wikipedia');
      expect(popContainer.querySelectorAll('.contact-program-help').length).to.eq(0);
    });
  });
});
