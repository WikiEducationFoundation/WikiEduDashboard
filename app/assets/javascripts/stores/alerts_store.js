import McFly from 'mcfly';
const Flux = new McFly();

let _needHelpAlertSubmitting = false;
let _needHelpAlertCreated = false;


const needHelpAlertSubmitted = function () {
  _needHelpAlertSubmitting = true;
};

const needHelpAlertCreated = function () {
  _needHelpAlertSubmitting = false;
  _needHelpAlertCreated = true;
};

const resetNeedHelpAlert = function () {
  _needHelpAlertSubmitting = false;
  _needHelpAlertCreated = false;
};

const storeMethods = {
  getNeedHelpAlertSubmitting() {
    return _needHelpAlertSubmitting;
  },
  getNeedHelpAlertSubmitted() {
    return _needHelpAlertCreated;
  }
};

const AlertsStore = Flux.createStore(storeMethods, (payload) => {
  let needsUpdate = false;

  switch (payload.actionType) {
    case 'NEED_HELP_ALERT_SUBMITTED':
      needHelpAlertSubmitted();
      needsUpdate = true;
      break;
    case 'NEED_HELP_ALERT_CREATED':
      needHelpAlertCreated();
      needsUpdate = true;
      break;
    case 'RESET_NEED_HELP_ALERT':
      resetNeedHelpAlert();
      needsUpdate = true;
      break;
    default:
      // No default
  }

  if (needsUpdate) {
    AlertsStore.emitChange();
  }
});

export default AlertsStore;
