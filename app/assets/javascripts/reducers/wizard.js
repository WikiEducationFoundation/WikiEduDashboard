import I18n from 'i18n-js';
import {
  RECEIVE_WIZARD_ASSIGNMENT_OPTIONS,
  RECEIVE_WIZARD_PANELS,
  SELECT_WIZARD_OPTION,
  // EXPAND_WIZARD_OPTION,
  WIZARD_ADVANCE,
  WIZARD_REWIND,
  WIZARD_GOTO,
  // WIZARD_RESET,
  // WIZARD_SUBMITTED
} from '../constants';

const assignmentsPanel = (options = []) => {
  return {
    title: I18n.t('wizard.assignment_type'),
    description: I18n.t('wizard.select_assignment'),
    options,
    type: 1,
    minimum: 1,
    key: 'index'
  };
};

const datesPanel = {
  title: I18n.t('wizard.course_dates'),
  description: '',
  options: [],
  type: -1,
  minimum: 0,
  key: 'dates'
};

const summaryPanel = {
  title: I18n.t('wizard.summary'),
  description: I18n.t('wizard.review_selections'),
  options: [],
  type: -1,
  minimum: 0,
  key: 'summary'
};

const panels = (assignmentOptions = [], extraPanels = []) => {
  return [
    datesPanel,
    assignmentsPanel(assignmentOptions),
    ...extraPanels,
    summaryPanel
  ];
};

const updatedPanelSelections = (oldPanels, panelIndex, optionIndex) => {
  const newPanels = [...oldPanels];
  const updatedPanel = { ...newPanels[panelIndex] };
  const updatedOptions = [...updatedPanel.options];
  updatedOptions[optionIndex].selected = !updatedOptions[optionIndex].selected;
  updatedPanel.options = updatedOptions;
  newPanels[panelIndex] = updatedPanel;
  return newPanels;
};

const initialState = {
  activeIndex: 0,
  summary: false,
  wizardKey: null,
  assignmentOptions: [],
  panels: panels()
};

export default function wizard(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_WIZARD_ASSIGNMENT_OPTIONS: {
      const assignmentOptions = action.assignmentOptions;
      return { ...state, assignmentOptions, panels: panels(assignmentOptions) };
    }
    case RECEIVE_WIZARD_PANELS: {
      const extraPanels = action.extraPanels;
      return { ...state, panels: panels(state.assignmentOptions, extraPanels) };
    }
    case SELECT_WIZARD_OPTION: {
      return { ...state, panels: updatedPanelSelections(state.panels, action.panelIndex, action.optionIndex) };
    }
    case WIZARD_ADVANCE: {
      return { ...state, activeIndex: state.activeIndex + 1 };
    }
    case WIZARD_REWIND: {
      return { ...state, activeIndex: state.activeIndex - 1 };
    }
    case WIZARD_GOTO: {
      return { ...state, activeIndex: action.toPanelIndex };
    }
    default:
      return state;
  }
}
