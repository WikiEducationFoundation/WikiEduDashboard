import _ from 'lodash';
import {
  ASSIGNMENTS_PANEL_INDEX,
  RECEIVE_WIZARD_ASSIGNMENT_OPTIONS,
  SELECT_WIZARD_OPTION,
  SELECT_WIZARD_ASSIGNMENT,
  WIZARD_ADVANCE,
  WIZARD_REWIND,
  WIZARD_GOTO,
  WIZARD_ENABLE_SUMMARY_MODE,
  WIZARD_DISABLE_SUMMARY_MODE,
  RECEIVE_WIZARD_PANELS,
  API_FAIL
} from '../constants';

import logErrorMessage from '../utils/log_error_message';

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

export const fetchWizardIndex = () => (dispatch) => {
  return fetchWizardIndexPromise()
    .then((data) => {
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

export const fetchWizardPanels = wizardId => (dispatch) => {
  return fetchWizardPanelsPromise(wizardId)
    .then((data) => {
      dispatch({ type: RECEIVE_WIZARD_PANELS, extraPanels: data });
      // Using a 0 timeout here gives the browser a chance
      // to re-render the new off-screen panels before the
      // advance to the next slide and helps ensure a smooth
      // panel transition.
      setTimeout(dispatch, 0, { type: WIZARD_ADVANCE });
    })
    .catch(data => dispatch({ type: API_FAIL, data }));
};

export const advanceWizard = () => (dispatch, getState) => {
  const state = getState();
  // If we're advancing from the Assignments panel,
  // we need to fetch the specific wizard panel for the selected
  // assignment option.
  if (state.wizard.activeIndex === ASSIGNMENTS_PANEL_INDEX) {
    const wizardKey = getWizardKey(state.wizard);
    fetchWizardPanels(wizardKey)(dispatch);
  // If we're advancing from the second-to-last panel to the final summary panel,
  // enable summary mode.
  } else if (state.wizard.activeIndex === state.wizard.panels.length - 2) {
    dispatch({ type: WIZARD_ENABLE_SUMMARY_MODE });
    dispatch({ type: WIZARD_ADVANCE });
  } else {
    dispatch({ type: WIZARD_ADVANCE });
  }
};

export const selectWizardOption = (panelIndex, optionIndex) => (dispatch) => {
  dispatch({ type: SELECT_WIZARD_OPTION, panelIndex, optionIndex });
  // If an assignment selection is made, disable summary mode.
  // Changing the selected assignment clears the wizard, so you can't
  // return directly to the summary.
  if (panelIndex === ASSIGNMENTS_PANEL_INDEX) {
    dispatch({ type: SELECT_WIZARD_ASSIGNMENT, optionIndex });
    dispatch({ type: WIZARD_DISABLE_SUMMARY_MODE });
  }
};

export const rewindWizard = () => {
  return { type: WIZARD_REWIND };
};

export const goToWizard = (toPanelIndex) => {
  return { type: WIZARD_GOTO, toPanelIndex };
};

export const enableSummaryMode = () => {
  return { type: WIZARD_ENABLE_SUMMARY_MODE };
};

export const disableSummaryMode = () => {
  return { type: WIZARD_DISABLE_SUMMARY_MODE };
};

const submitWizardPromise = (courseSlug, wizardId, wizardOutput) => {
  return new Promise((res, rej) =>
    $.ajax({
      type: 'POST',
      url: `/courses/${courseSlug}/wizard/${wizardId}.json`,
      contentType: 'application/json',
      data: JSON.stringify({ wizard_output: wizardOutput }),
      success(data) {
        return res(data);
      }
    })
    .fail((obj) => {
      logErrorMessage(obj, 'Couldn\'t submit wizard answers! ');
      return rej(obj);
    })
  );
};

const getWizardKey = (state) => {
  const assignmentOptions = state.assignmentOptions;
  return _.find(assignmentOptions, option => option.selected).key;
};

const getWizardOutput = (state) => {
  let output = [];
  const logic = [];
  const tags = [];
  state.panels.forEach((panel) => {
    if (Array.isArray(panel.output)) {
      output = output.concat(panel.output);
    } else {
      output.push(panel.output);
    }
    if (panel.options !== undefined && panel.options.length > 0) {
      return panel.options.forEach((option) => {
        if (!option.selected) { return; }
        if (option.output) {
          if (Array.isArray(option.output)) {
            output = output.concat(option.output);
          } else {
            output.push(option.output);
          }
        }
        if (option.logic) { logic.push(option.logic); }
        if (option.tag) { return tags.push({ key: panel.key, tag: option.tag }); }
      });
    }
  });
  return { output, logic, tags };
};

export const submitWizard = courseSlug => (_dispatch, getState) => {
  const wizardState = getState().wizard;
  submitWizardPromise(courseSlug, getWizardKey(wizardState), getWizardOutput(wizardState))
    .then(() => {
      // reload the timeline tab with the new timeline
      window.location = `/${window.location.pathname.split('/').splice(1, 4).join('/')}`;
    });
};
