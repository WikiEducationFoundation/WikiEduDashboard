import McFly from 'mcfly';
const Flux = new McFly();

let _confirmationActive = false;

const storeMethods = {
  isConfirmationActive() {
    return _confirmationActive;
  }
};

const ConfirmationStore = Flux.createStore(storeMethods, (payload) => {
  switch (payload.actionType) {
    case 'CONFIRMATION_INITIATED':
      _confirmationActive = true;
      return ConfirmationStore.emitChange();
    case 'ACTION_CONFIRMED':
      _confirmationActive = false;
      return ConfirmationStore.emitChange();
    case 'ACTION_CANCELLED':
      _confirmationActive = false;
      return ConfirmationStore.emitChange();
    default:
      // no default
  }
});

ConfirmationStore.setMaxListeners(0);

export default ConfirmationStore;
