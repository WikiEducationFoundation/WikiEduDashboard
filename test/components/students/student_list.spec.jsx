import '../../testHelper';
import sinon from 'sinon';
import React from 'react';
import ReactTestUtils from 'react-addons-test-utils';
import StudentList from '../../../app/assets/javascripts/components/students/student_list.jsx';
import ServerActions from '../../../app/assets/javascripts/actions/server_actions.js';
describe('Student', () => {

  const currentUser = { id: 1, admin: true, role: 1 };
  const users = [{
    role: 0,
    id: 3,
    username: "Adam",
    admin: false,
    course_training_progress: "0/3 training modules completed",
    real_name: null
  }];
  const params = { course_school: "Foobar", course_id: "asd" }
  const assignments = [
    {
      article_id: 7,
      article_title: "Foo",
      article_url: "https://en.wikipedia.org/wiki/Foo",
      assignment_id: 10,
      course_id: "Couse_school/Test_Course_(Couse_term)",
      id: 10,
      role: 1,
      user_id: 3,
      username: "Adam",
      admin: false
    }
  ];
  const course = {
    student_count: 1,
    trained_count: 0,
    published: true,
    home_wiki: { language: 'en', project: 'wikipedia' }
  };
  function confirm(){

  }
  it('displays \'Name\' column', () => {
    const studentList = ReactTestUtils.renderIntoDocument(
      <table>
        <StudentList params={params} users={users} course={course} editable={true} current_user ={currentUser} assignments={assignments} />
      </table>
    );
    expect(studentList.textContent).to.contain('Name');
  }
  );
  it('calls ServerActions.notifyOverdue', () => {
    const studentList = ReactTestUtils.renderIntoDocument(
      <StudentList params={params} editable={true} users={users} course={course} current_user ={currentUser} assignments={assignments} />
    );
    studentList.setState( {users: users} );
    studentList.setState( {assignments: assignments} );

    const controls = ReactTestUtils.findRenderedDOMComponentWithClass(studentList, 'controls');
    const button = controls.querySelectorAll('button.notify_overdue')[0];
    global.Features = { wikiEd: true }
    var confirm;
    confirm = sinon.spy();
    var notifyOverdue = sinon.spy(ServerActions, 'notifyOverdue');
    ReactTestUtils.Simulate.click(button)
    expect(notifyOverdue.callCount).to.eq(1);
  }
  );
}
);
