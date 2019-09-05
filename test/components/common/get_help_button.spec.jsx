import React from 'react';
import { mount } from 'enzyme';
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

    const TestGetHelpButton = mount(
      <Provider store={reduxStoreWithUsers}>
        <GetHelpButton currentUser={currentUser} key="get_help" course={course} />
      </Provider>
    );

    const popContainer = TestGetHelpButton.find('.pop__container');

    it('renders the get help button', () => {
      const getHelpButton = popContainer.find('button.small');
      expect(getHelpButton.length).to.eq(1);
      expect(getHelpButton.text()).to.eq('Get Help');
    });

    it('has an ask search field', () => {
      const searchField = popContainer.find('input#q');
      expect(searchField.length).to.eq(1);
      expect(searchField.prop('placeholder')).to.eq('Search Help Forum');
    });
  });

  describe('Interactions', () => {
    const currentUser = { isAdvancedRole: 1 };

    it('should be collapsed by default', () => {
      const TestGetHelpButton = mount(
        <Provider store={reduxStoreWithUsers}>
          <GetHelpButton currentUser={currentUser} key="get_help" course={course} />
        </Provider>
      );

      const popContainer = TestGetHelpButton.find('.pop__container');
      const pop = popContainer.find('.pop');
      expect(pop.prop('className').includes('open')).to.eq(false);
    });

    it('should open when clicked', () => {
      const TestGetHelpButton = mount(
        <Provider store={reduxStoreWithUsers}>
          <GetHelpButton
            course={course}
            currentUser={currentUser}
            is_open
            key="get_help"
          />
        </Provider>
      );

      const popContainer = TestGetHelpButton.find('.pop__container');
      const pop = popContainer.find('.pop.open');
      expect(pop.prop('className').includes('open')).to.eq(true);
    });

    it('should switch to form', () => {
      const container = mount(
        <Provider store={reduxStoreWithUsers}>
          <GetHelpButton
            course={course}
            currentUser={currentUser}
            is_open
            key="get_help"
          />
        </Provider>
      );

      const popContainer = container.find('GetHelpButton');
      popContainer.setState({ selectedTargetUser: {} });
      expect(popContainer.find('.get-help-info')).to.exist;
      expect(popContainer.find('.get-help-form')).to.exist;
    });
  });

  describe('As an instructor', () => {
    const currentUser = { isAdvancedRole: true };

    const TestGetHelpButton = mount(
      <Provider store={reduxStoreWithUsers}>
        <GetHelpButton currentUser={currentUser} key="get_help" course={course} />
      </Provider>
    );

    const popContainer = TestGetHelpButton.find('.pop__container');

    it('lists the both wikipedia help and program help', () => {
      const wikipediaHelp = popContainer.find('.contact-wikipedia-help');
      const programHelp = popContainer.find('.contact-program-help');

      expect(wikipediaHelp.text()).to.eq('question about editing Wikipedia');
      expect(programHelp.text()).to.eq('question about Wiki Ed or your assignment');
    });
  });

  describe('As a student', () => {
    const currentUser = { isStudent: true };

    const TestGetHelpButton = mount(
      <Provider store={reduxStoreWithUsers}>
        <GetHelpButton currentUser={currentUser} key="get_help" course={course} />
      </Provider>
    );

    const popContainer = TestGetHelpButton.find('.pop__container');

    it('only lists the content expert', () => {
      const contentExperts = popContainer.find('.contact-wikipedia-help');
      expect(contentExperts.text()).to.eq('question about editing Wikipedia');
      expect(popContainer.find('.contact-program-help').length).to.eq(0);
    });
  });
});
