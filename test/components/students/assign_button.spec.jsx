import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import AssignButton from '../../../app/assets/javascripts/components/students/assign_button.jsx';
import { click } from '../../customUtils.js';

describe('AssignButton', () => {
  const currentUser = { id: 1, admin: false };
  const student = {
    role: 0,
    user_id: 4,
    id: 3,
    username: "Adam",
    first_name: "Adam",
    admin: false,
    course_training_progress: "0/3 training modules completed",
    real_name: null
  };
  const courseId = "Couse_school/Foo_(Couse_term)";
  const course = {
    student_count: 1,
    trained_count: 0,
    published: true,
    home_wiki: { language: 'en', project: 'wikipedia' }
  };
  const assigned = [
    {
      id: 9,
      article_title: "Foo",
      course_id: "Couse_school/Foo_(Couse_term)",
      assignment_id: 9,
      article_url: "https://en.wikipedia.org/wiki/Foo",
      username: "Adam"
    }
  ];
  it('renders article title', () => {
    const assignbutton = ReactTestUtils.renderIntoDocument(
      <div>
        <AssignButton student={student} course={course} course_id={courseId} is_open={false} role={0} current_user={currentUser} assignments={assigned} />
      </div>
    );
    expect(assignbutton.textContent).to.contain('Foo');
  }
  );
  it('opens popover', () => {
    const assignbutton = ReactTestUtils.renderIntoDocument(
      <AssignButton student={student} course={course} course_id={courseId} is_open={false} role={0} current_user={currentUser} assignments={assigned} />
    );
    expect(assignbutton.props.is_open).to.eq(false);
    click(assignbutton).then(() => {
      expect(assignbutton.props.is_open).to.eq(true);
      done();
    });
  }
  );
}
);
