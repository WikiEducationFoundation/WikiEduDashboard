import McFly from 'mcfly';
const Flux = new McFly();

const ConfirmActions = Flux.createActions({
  actionConfirmed() {
    return {
      actionType: 'ACTION_CONFIRMED',
      data: {}
    };
  },

  actionCancelled() {
    return {
      actionType: 'ACTION_CANCELLED',
      data: {}
    };
  }
});

export default ConfirmActions;
