import '../testHelper';
import { addAssignment, deleteAssignment } from '../../app/assets/javascripts/actions/assignment_actions.js';

describe('AssignmentActions', () => {
  const testAssignment = { title: 'Foo', user_id: 1, id: 4 };
  const initialAssignments = [];
  sinon.stub($, 'ajax').yieldsTo('success', { assignment: testAssignment });
  it('.addAssignment sets a new assignment and .deleteAssignment removes one', () => {
    expect(reduxStore.getState().assignments.assignments).to.deep.eq(initialAssignments);
    addAssignment(testAssignment)(reduxStore.dispatch)
      .then(() => {
        const updatedAssignments = reduxStore.getState().assignments.assignments;
        expect(updatedAssignments[0].article_title).to.eq(testAssignment.title);
        expect(updatedAssignments[0].user_id).to.eq(testAssignment.user_id);
        expect(updatedAssignments.length).to.eq(1);
      })
      .then(() => {
        const updatedAssignments = reduxStore.getState().assignments.assignments;
        deleteAssignment(updatedAssignments[0])(reduxStore.dispatch);
      })
      .then(() => {
        const assignmentsAfterDelete = reduxStore.getState().assignments.assignments;
        expect(assignmentsAfterDelete.length).to.eq(0);
      });
  });
});
