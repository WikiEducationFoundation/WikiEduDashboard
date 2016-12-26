import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
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
      assignment_id: 9,
      article_url: "https://en.wikipedia.org/wiki/Foo",
      username: "Adam",
      course_id: "Couse_school/Test_Course_(Couse_term)"
    }
  ];
  const course = {
    home_wiki: { language: 'en', project: 'wikipedia', published: true }
  };
  const studentElement = ReactTestUtils.renderIntoDocument(
    <div>
      <Student student={studentUser} course={course} editable={false} published={true} current_user ={currentUser} assigned={assigned} />
    </div>
  );
  it('renders', () => {
    expect(studentElement.textContent).to.contain('Adam');
  }
  );
  it('opens drawer', () => {
    const row = studentElement.querySelector('tr');
    click(row).then(() => {
      expect(row.className).to.contain('open');
      done();
    });
  }
  );
}
);
