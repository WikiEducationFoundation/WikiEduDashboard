import { RECEIVE_WIZARD_ASSIGNMENT_OPTIONS, API_FAIL } from '../constants';
import logErrorMessage from '../utils/log_error_message';
import McFly from 'mcfly';
const Flux = new McFly();

const WizardActions = Flux.createActions({
  toggleOptionSelected(panelIndex, optionIndex) {
    return {
      actionType: 'SELECT_OPTION',
      data: {
        panel_index: panelIndex,
        option_index: optionIndex
      }
    };
  },

  toggleOptionExpanded(panelIndex, optionIndex) {
    return {
      actionType: 'EXPAND_OPTION',
      data: {
        panel_index: panelIndex,
        option_index: optionIndex
      }
    };
  },

  rewindWizard(toIndex = null) {
    return {
      actionType: 'WIZARD_REWIND',
      data: { toIndex }
    };
  },

  advanceWizard() {
    return { actionType: 'WIZARD_ADVANCE' };
  },

  resetWizard() {
    return { actionType: 'WIZARD_RESET' };
  },

  goToWizard(toIndex = 0) {
    return {
      actionType: 'WIZARD_GOTO',
      data: { toIndex }
    };
  },
  receiveWizardIndex(resp) {
    return {
      actionType: 'RECEIVE_WIZARD_INDEX',
      data: {
        wizard_index: resp
      }
    };
  }
});


const fetchWizardIndexPromise = () => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'GET',
      url: '/wizards.json',
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    })
  );
};

export const fetchWizardIndex = () => dispatch => {
  return fetchWizardIndexPromise()
    .then(data => {
      WizardActions.receiveWizardIndex(data);
      dispatch({ type: RECEIVE_WIZARD_ASSIGNMENT_OPTIONS, assignmentOptions: data });
    })
    .catch(data => dispatch({ type: API_FAIL, data }));
};


const fetchWizardPanelsPromise = (wizardId) => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'GET',
      url: `/wizards/${wizardId}.json`,
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj);
      return rej(obj);
    })
  );
};

export const fetchWizardPanels = (wizardId) => dispatch => {
  return fetchWizardPanelsPromise(wizardId)
    .then(data => {
      WizardActions.receiveWizardIndex(data);
      dispatch({ type: RECEIVE_WIZARD_PANELS, extraPanels: data });
    })
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const wizardAdvance = () => (dispatch, getState) => {
  WizardActions.wizardAdvance(data);
  dispatch({ type: WIZARD_ADVANCE });
  const state = getState();
  // if (state.wizard.activeIndex == 1) {

  // }
};

export default WizardActions;
