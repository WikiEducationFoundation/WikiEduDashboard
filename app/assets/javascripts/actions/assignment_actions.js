import McFly from 'mcfly';
const Flux = new McFly();

const AssignmentActions = Flux.createActions({
  addAssignment(assignment) {
    return {
      actionType: 'ADD_ASSIGNMENT',
      data: {
        user_id: assignment.user_id,
        article_title: assignment.title,
        language: assignment.language,
        project: assignment.project,
        role: assignment.role,
        article_url: assignment.article_url
      }
    };
  },

  deleteAssignment(assignment) {
    return {
      actionType: 'DELETE_ASSIGNMENT',
      data: {
        model: assignment
      }
    };
  }
});

export default AssignmentActions;
