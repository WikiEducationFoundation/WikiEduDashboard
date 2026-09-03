import '../testHelper';
import { addAssignment, copyAvailableArticles, deleteAssignment } from '../../app/assets/javascripts/actions/assignment_actions.js';
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

  test(
    '.copyAvailableArticles replaces the assignments list with the response',
    (done) => {
      const copyResponse = {
        created: 2,
        skipped: 1,
        course: { assignments: [{ id: 7, article_title: 'Copied', user_id: null, role: 0 }] }
      };
      requestModule.default.restore();
      sinon.stub(requestModule, 'default').resolves(
        { status: 200, ok: true, json: sinon.fake.returns(copyResponse) }
      );
      const opts = { course_slug: 'School/Target_(Term)', source: 'School/Source_(Term)', include_student_assigned: false };
      copyAvailableArticles(opts)(reduxStore.dispatch)
        .then(() => {
          const state = reduxStore.getState();
          expect(state.assignments.assignments.map(a => a.article_title)).toEqual(['Copied']);
          expect(state.assignments.loading).toBe(false);
          done();
        });
    }
  );
});
