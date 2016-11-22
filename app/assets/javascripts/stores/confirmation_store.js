import McFly from 'mcfly';
const Flux = new McFly();

const ConfirmationStore = Flux.createStore({}, (payload) => {
  switch (payload.actionType) {
    case 'ACTION_CONFIRMED':
      return ConfirmationStore.emitChange();
    case 'ACTION_CANCELLED':
      return ConfirmationStore.emitChange();
    default:
      // no default
  }
});

ConfirmationStore.setMaxListeners(0);

export default ConfirmationStore;
