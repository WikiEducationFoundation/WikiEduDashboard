import '../../testHelper';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
<<<<<<< HEAD
import ReactDom from 'react-dom';

=======
>>>>>>> 0f1fa6e94eb84d5db50205f2ff83ef47339000fa
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
<<<<<<< HEAD
  it('runs assign()', () => {
=======
  it('opens popover', () => {
>>>>>>> 0f1fa6e94eb84d5db50205f2ff83ef47339000fa
    const assignbutton = ReactTestUtils.renderIntoDocument(
      <AssignButton student={student} course={course} course_id={courseId} is_open={false} role={0} current_user={currentUser} assignments={assigned} />
    );
    expect(assignbutton.props.is_open).to.eq(false);
<<<<<<< HEAD
    const pop = ReactTestUtils.findRenderedDOMComponentWithClass(assignbutton, 'pop__container');
    click(pop).then(() => {
      expect(assignbutton.props.is_open).to.eq(true);
      const edit = ReactTestUtils.findRenderedDOMComponentWithClass(pop, 'edit');
      const submitButton = ReactTestUtils.findRenderedDOMComponentWithClass(edit, 'button');
      const input = ReactTestUtils.findRenderedDOMComponentWithClass(edit, 'Lookup');
      const inputNode = ReactDOM.findDOMNode(input);
      inputNode.value="Foobar";
      ReactTestUtils.Simulate.click(submitButton);
      const finalSubmit = ReactTestUtils.findRenderedDOMComponentWithClass(pop, 'button dark');
      ReactTestUtils.Simulate.click(finalSubmit);
      done();
    });

=======
    click(assignbutton).then(() => {
      expect(assignbutton.props.is_open).to.eq(true);
      done();
    });
>>>>>>> 0f1fa6e94eb84d5db50205f2ff83ef47339000fa
  }
  );
}
);
