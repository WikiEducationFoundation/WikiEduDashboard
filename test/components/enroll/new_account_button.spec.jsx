import 'testHelper';
import React from 'react';
import { mount } from 'enzyme';
import NewAccountButton from '../../../app/assets/javascripts/components/enroll/new_account_button.jsx';

describe('NewAccountButton', () => {
  const currentUser = { admin: false, id: null, notEnrolled: true };
  const course = {
    student_count: 1,
    trained_count: 0,
    published: true,
    home_wiki: { language: 'en', project: 'wikipedia' },
    passcode: 'passcode',
    course_id: "Course_school/Test_Course_(Course_term)"
  };

  it('renders a NewAccountModal when is clicked', () => {
    const component = mount(
      <NewAccountButton
        currentUser={currentUser}
        course={course}
        passcode={course.passcode}
        />
    );
    expect(component.instance().state.showModal).to.eq(false);
    // click the initial button to show the modal
    component.find('.button').simulate('click');
    expect(component.instance().state.showModal).to.eq(true);
    // trigger the outside click handler to close the modal
    component.instance().handleClickOutside();
    expect(component.instance().state.showModal).to.eq(false);
  });
});
