import '../testHelper';
import AssignmentActions from '../../app/assets/javascripts/actions/assignment_actions.js';
import AssignmentStore from '../../app/assets/javascripts/stores/assignment_store.js';

describe('AssignmentActions', () => {
  it('.addAssignment sets a new assignment', (done) => {
    expect(AssignmentStore.getModels().length).to.eq(0);
    AssignmentActions.addAssignment({ title: 'Foo', id: 1 }).then(() => {
      expect(AssignmentStore.getModels().length).to.eq(1);
      done();
    });
  });

  it('.deleteAssignment removes the specified assignment', (done) => {
    expect(AssignmentStore.getModels().length).to.eq(1);
    const assignment = AssignmentStore.getModels()[0];
    AssignmentActions.deleteAssignment(assignment).then(() => {
      expect(AssignmentStore.getModels().length).to.eq(0);
      done();
    });
  });
});
