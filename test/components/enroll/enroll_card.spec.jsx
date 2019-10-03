import React from 'react';
import { mount } from 'enzyme';
import '../../testHelper';
import EnrollCard from '../../../app/assets/javascripts/components/enroll/enroll_card.jsx';


describe('EnrollCard', () => {
  const currentUser = { admin: false, id: null, notEnrolled: true };
  const course = {
    student_count: 1,
    trained_count: 0,
    published: true,
    home_wiki: { language: 'en', project: 'wikipedia' },
    passcode: 'passcode',
    course_id: 'Course_school/Test_Course_(Course_term)',
    flags: { register_accounts: true }
  };

  it('Shows a new account button if the user is not logged in', () => {
    const TestEnrollCard = mount(
      <EnrollCard
        user={currentUser}
        userRoles={currentUser}
        course={course}
      />
    );
    const button = TestEnrollCard.find('.button.auth.signup.border');
    expect(button.length).toEqual(1);
  });

  it('Warns about ended course', () => {
    const TestEnrollCard = mount(
      <EnrollCard
        course={{ ended: true }}
      />
    );
    const h1 = TestEnrollCard.find('h1');
    expect(h1.first().text()).toEqual('The course has ended.');
    });
  }
);
