import McFly from 'mcfly';
const Flux = new McFly();

// Data
let _openKey = null;


// Private methods
const setOpenKey = function (key) {
  if (key === _openKey) {
    _openKey = null;
  } else {
    _openKey = key;
  }
};

// Store
const storeMethods = {
  getOpenKey() {
    return _openKey;
  },
};
const UIStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'OPEN_KEY':
      setOpenKey(data.key);
      UIStore.emitChange();
      break;
    default:
      // no default
  }
  return true;
});

UIStore.setMaxListeners(0);

export default UIStore;
