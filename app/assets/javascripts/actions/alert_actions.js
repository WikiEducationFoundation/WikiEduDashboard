import McFly from 'mcfly';
const Flux = new McFly();
import API from '../utils/api.js';

const AlertActions = Flux.createActions({
  submitNeedHelpAlert(data) {
    AlertActions.createNeedHelpAlert(data);
    return {
      actionType: 'NEED_HELP_ALERT_SUBMITTED',
      data: {}
    };
  },

  createNeedHelpAlert(data) {
    return API.createNeedHelpAlert(data)
      .then(resp => ({ actionType: 'NEED_HELP_ALERT_CREATED', data: resp }))
      .catch(resp => ({ actionType: 'API_FAIL', data: resp }));
  },

  resetNeedHelpAlert() {
    return {
      actionType: 'RESET_NEED_HELP_ALERT',
      data: {}
    };
  }
});

export default AlertActions;
