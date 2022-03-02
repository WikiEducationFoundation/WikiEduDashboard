import '../testHelper';
import { addAssignment, deleteAssignment } from '../../app/assets/javascripts/actions/assignment_actions.js';
import * as requestModule from '../../app/assets/javascripts/utils/request';


describe('AssignmentActions', () => {
  const testAssignment = { article_title: 'Foo', user_id: 1, id: 4 };
  const initialAssignments = [];
  sinon.stub(requestModule, 'default').resolves(
    { status: 200, ok: true, json: sinon.fake.returns(testAssignment) }
  );
  test(
    '.addAssignment sets a new assignment and .deleteAssignment removes one',
    (done) => {
      expect(reduxStore.getState().assignments.assignments).toEqual(initialAssignments);
      addAssignment(testAssignment)(reduxStore.dispatch)
        .then(() => {
          const updatedAssignments = reduxStore.getState().assignments.assignments;
          expect(updatedAssignments[0].article_title).toBe(testAssignment.article_title);
          expect(updatedAssignments[0].user_id).toBe(testAssignment.user_id);
          expect(updatedAssignments.length).toBe(1);
        })
        .then(() => {
          const updatedAssignments = reduxStore.getState().assignments.assignments;
          const deletionResponse = { assignmentId: updatedAssignments[0].id };
          requestModule.default.restore();
          sinon.stub(requestModule, 'default').resolves(
            { status: 200, ok: true, json: sinon.fake.returns({ ...deletionResponse }) }
          );
          return deleteAssignment(updatedAssignments[0])(reduxStore.dispatch);
        })
        .then(() => {
          const assignmentsAfterDelete = reduxStore.getState().assignments.assignments;
          expect(assignmentsAfterDelete.length).toBe(0);
          done();
        });
    }
  );
});
