import McFly from 'mcfly';
const Flux = new McFly();

const RevisionActions = Flux.createActions({
  getRevisions(studentId) {
    return {
      actionType: 'GET_STUDENT_REVISIONS',
      data: {
        revisions: studentId
      }
    };
  }
});

export default RevisionActions;
