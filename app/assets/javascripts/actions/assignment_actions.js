import McFly from 'mcfly';
const Flux = new McFly();

const AssignmentActions = Flux.createActions({
  addAssignment(courseId, userId, articleTitle, role) {
    return {
      actionType: 'ADD_ASSIGNMENT',
      data: {
        user_id: userId,
        article_title: articleTitle,
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
