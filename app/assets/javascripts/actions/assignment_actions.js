import McFly from 'mcfly';
const Flux = new McFly();

const AssignmentActions = Flux.createActions({
  addAssignment(courseId, userId, articleId, role) {
    return {
      actionType: 'ADD_ASSIGNMENT',
      data: {
        user_id: userId,
        article_id: articleId,
        role
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
