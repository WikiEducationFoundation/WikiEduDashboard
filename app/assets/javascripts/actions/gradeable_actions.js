import McFly from 'mcfly';
const Flux = new McFly();

const GradeableActions = Flux.createActions({
  addGradeable(block) {
    return {
      actionType: 'ADD_GRADEABLE',
      data: {
        block
      }
    };
  },

  updateGradeable(gradeable) {
    return {
      actionType: 'UPDATE_GRADEABLE',
      data: {
        gradeable
      }
    };
  },

  deleteGradeable(gradeableId) {
    return {
      actionType: 'DELETE_GRADEABLE',
      data: {
        gradeable_id: gradeableId
      }
    };
  }
});

export default GradeableActions;
