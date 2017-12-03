import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import Student from '../../../app/assets/javascripts/components/students/student.jsx';
import { click } from '../../customUtils.js';

describe('Student', () => {
  const currentUser = { id: 1 };
  const studentUser = {
    role: 0,
    id: 3,
    username: "Adam",
    admin: false,
    course_training_progress: "0/3 training modules completed",
    real_name: null
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
  const course = {
    published: true,
    home_wiki: { language: 'en', project: 'wikipedia' }
  };
  const studentElement = ReactTestUtils.renderIntoDocument(
    <table>
      <tbody>
        <Student
          store={reduxStore}
          student={studentUser}
          course={course}
          course_id="Couse_school/Foo_(Couse_term)"
          editable={false}
          published={true}
          current_user={currentUser}
          assigned={assigned}
          assignments={assigned}
          reviewing={assigned}
        />
      </tbody>
    </table>
  );
  it('displays the name of the user', () => {
    expect(studentElement.textContent).to.contain('Adam');
  });
  it('opens drawer when clicked', () => {
    const row = studentElement.querySelector('tr');
    expect(row.className).to.eq('students');
    click(row).then(() => {
      expect(row.className).to.contain('open');
      done();
    });
  });
});
