import '../testHelper';
import { addAssignment, deleteAssignment } from '../../app/assets/javascripts/actions/assignment_actions.js';

describe('AssignmentActions', () => {
  const testAssignment = { article_title: 'Foo', user_id: 1, id: 4 };
  const initialAssignments = [];
  sinon.stub($, 'ajax').yieldsTo('success', testAssignment);
  it('.addAssignment sets a new assignment and .deleteAssignment removes one', (done) => {
    expect(reduxStore.getState().assignments.assignments).to.deep.eq(initialAssignments);
    addAssignment(testAssignment)(reduxStore.dispatch)
      .then(() => {
        const updatedAssignments = reduxStore.getState().assignments.assignments;
        expect(updatedAssignments[0].article_title).to.eq(testAssignment.article_title);
        expect(updatedAssignments[0].user_id).to.eq(testAssignment.user_id);
        expect(updatedAssignments.length).to.eq(1);
      })
      .then(() => {
        const updatedAssignments = reduxStore.getState().assignments.assignments;
        const deletionResponse = { assignmentId: updatedAssignments[0].id };
        $.ajax.restore();
        sinon.stub($, 'ajax').yieldsTo('success', deletionResponse);
        deleteAssignment(updatedAssignments[0])(reduxStore.dispatch);
      })
      .then(() => {
        const assignmentsAfterDelete = reduxStore.getState().assignments.assignments;
        expect(assignmentsAfterDelete.length).to.eq(0);
        done();
      });
  });
});
