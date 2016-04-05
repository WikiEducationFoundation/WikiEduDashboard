import McFly from 'mcfly';
const Flux = new McFly();

const TrainingActions = Flux.createActions({
  toggleMenuOpen(opts) {
    return {
      actionType: 'MENU_TOGGLE',
      data: {
        currently: opts.currently
      }
    };
  },

  setSelectedAnswer(answer) {
    return {
      actionType: 'SET_SELECTED_ANSWER',
      data: {
        answer
      }
    };
  },

  setCurrentSlide(slideId) {
    return {
      actionType: 'SET_CURRENT_SLIDE',
      data: {
        slide: slideId
      }
    };
  }
});


export default TrainingActions;
