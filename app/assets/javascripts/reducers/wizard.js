import {
  RECEIVE_WIZARD_ASSIGNMENT_OPTIONS,
  RECEIVE_WIZARD_PANELS,
  SELECT_WIZARD_OPTION,
  EXPAND_WIZARD_OPTION,
  WIZARD_ADVANCE,
  WIZARD_REWIND,
  WIZARD_GOTO,
  WIZARD_RESET,
  WIZARD_SUBMITTED
} from '../constants';


const assignmentsPanel = (options = []) => {
  return {
    title: I18n.t('wizard.assignment_type'),
    description: I18n.t('wizard.select_assignment'),
    active: false,
    options,
    type: 1,
    minimum: 1,
    key: 'index'
  };
};

const datesPanel = {
  title: I18n.t('wizard.course_dates'),
  description: '',
  active: true,
  options: [],
  type: -1,
  minimum: 0,
  key: 'dates'
};

const summaryPanel = {
  title: I18n.t('wizard.summary'),
  description: I18n.t('wizard.review_selections'),
  active: false,
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
    case WIZARD_ADVANCE: {
      // oh my
      return { ...state, activeIndex: state.activeIndex + 1 };
    }
    default:
      return state;
  }
}
