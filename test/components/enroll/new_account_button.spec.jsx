import 'testHelper';
import React from 'react';
import { shallow } from 'enzyme';
import NewAccountButton from '../../../app/assets/javascripts/components/enroll/new_account_button.jsx';

describe('NewAccountButton', () => {
  const currentUser = { admin: false, id: null, notEnrolled: true };
  const course = {
    student_count: 1,
    trained_count: 0,
    published: true,
    home_wiki: { language: 'en', project: 'wikipedia' },
    passcode: 'passcode',
    course_id: 'Course_school/Test_Course_(Course_term)',
    account_requests_enabled: true
  };

  it('renders a NewAccountModal when is clicked', () => {
    const newAccountButton = shallow(
      <NewAccountButton
        currentUser={currentUser}
        course={course}
        passcode={course.passcode}
      />
    );
    expect(newAccountButton.instance().state.showModal).toEqual(false);
    // click the initial button to show the modal
    const button = newAccountButton.find('.button.auth.signup.border');
    expect(button.length).toEqual(1);
    button.simulate('click');
    expect(newAccountButton.instance().state.showModal).toEqual(true);
    // closes the modal
    newAccountButton.instance().closeModal();
    expect(newAccountButton.instance().state.showModal).toEqual(false);
  });
});
