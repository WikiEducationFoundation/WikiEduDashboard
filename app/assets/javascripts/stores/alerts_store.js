import McFly from 'mcfly';
const Flux = new McFly();

let _needHelpAlertSubmitting = false;
let _needHelpAlertCreated = false;


const needHelpAlertSubmitted = function () {
  _needHelpAlertSubmitting = true;
  return AlertsStore.emitChange();
};

const needHelpAlertCreated = function () {
  _needHelpAlertSubmitting = false;
  _needHelpAlertCreated = true;
  return AlertsStore.emitChange();
};

const resetNeedHelpAlert = function () {
  _needHelpAlertSubmitting = false;
  _needHelpAlertCreated = false;
  return AlertsStore.emitChange();
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
  switch (payload.actionType) {
    case 'NEED_HELP_ALERT_SUBMITTED':
      return needHelpAlertSubmitted();
    case 'NEED_HELP_ALERT_CREATED':
      return needHelpAlertCreated();
    case 'RESET_NEED_HELP_ALERT':
      return resetNeedHelpAlert();
    default:
      // no default
  }
});

export default AlertsStore;
