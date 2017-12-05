import McFly from 'mcfly';
const Flux = new McFly();
import _ from 'lodash';

import ServerActions from '../actions/server_actions.js';

let _activeIndex = 0;
let _summary = false;
let _wizardKey = null;
const _panels = [{
  title: I18n.t('wizard.course_dates'),
  description: '',
  active: true,
  options: [],
  type: -1,
  minimum: 0,
  key: 'dates'
}, {
  title: I18n.t('wizard.assignment_type'),
  description: I18n.t('wizard.select_assignment'),
  active: false,
  options: [],
  type: 1,
  minimum: 1,
  key: 'index'
}, {
  title: I18n.t('wizard.summary'),
  description: I18n.t('wizard.review_selections'),
  active: false,
  options: [],
  type: -1,
  minimum: 0,
  key: 'summary'
}];

// Utilities
const setIndex = function (index) {
  // index of the assignment panel
  _panels[1].options = index;
  return WizardStore.emitChange();
};

const setPanels = function (panels) {
  // 3 hard-coded panels: course dates, assignments, summary
  // _panels.length will change when more are inserted
  const toRemove = _panels.length - 3;
  // insert retrieved panels after hardcoded panels, but before summary
  // also remove if you chose a different assignment but went back
  // 3 (for now) is index of the first to remove (the first retrieved panel)
  _panels.splice.apply(_panels, [2, toRemove].concat(panels));
  if (_activeIndex > 0) { moveWizard(); }
  return WizardStore.emitChange();
};

const updateActivePanels = function () {
  if (_panels.length > 0) {
    _panels.forEach(panel => panel.active = false);
    return _panels[_activeIndex].active = true;
  }
};

const selectOption = function (panelIndex, optionIndex) {
  const panel = _panels[panelIndex];
  const option = panel.options[optionIndex];
  if (panel.type !== 0) { // multiple choice
    panel.options.forEach(panelOption => panelOption.selected = false);
  }
  option.selected = !(option.selected || false);
  verifyPanelSelections(panel);
  _summary = _summary && !(_activeIndex === 1 && _summary);
  return WizardStore.emitChange();
};

const expandOption = function (panelIndex, optionIndex) {
  const panel = _panels[panelIndex];
  const option = panel.options[optionIndex];
  option.expanded = !(option.expanded || false);
  return WizardStore.emitChange();
};

const moveWizard = function (backwards = false, toIndex = null) {
  const activePanel = _panels[_activeIndex];
  let increment = backwards ? -1 : 0;

  if (!backwards && verifyPanelSelections(activePanel)) {
    increment = 1;
    if (_activeIndex === 1) { // assignment step
      const selectedWizard = _.find(_panels[_activeIndex].options, o => o.selected);
      if (selectedWizard.key !== _wizardKey) {
        _wizardKey = selectedWizard.key;
        ServerActions.fetchWizardPanels(selectedWizard.key);
        increment = 0;
      }
    }
  }

  if (toIndex !== null) {
    _activeIndex = toIndex;
  } else {
    _activeIndex += increment;
  }

  if (backwards) { _summary = (toIndex !== null); }

  if (_activeIndex === -1) {
    _activeIndex = 0;
  } else if (_activeIndex === _panels.length || (_summary && !backwards)) {
    _activeIndex = _panels.length - 1;
  }

  // ####
  // THIS IS CHECK TO SEE IF WE NEED TO SCROLL PANEL TO TOP BEFORE TRANSITION
  // THERE IS PERHAPS A BETTER PLACE THAN THIS FILE TO PUT THIS EVENT/TRANSITION
  // ####
  const timeoutTime = increment !== 0 ? 150 : 0;
  if (timeoutTime > 0) {
    if ($('.wizard').scrollTop() > 0) {
      $('.wizard').animate(
        { scrollTop: 0 }
        , timeoutTime
      );
    }
  }

  return setTimeout(
    () => {
      updateActivePanels();
      return WizardStore.emitChange();
    }
    , timeoutTime
  );
};

const verifyPanelSelections = function (panel) {
  if (panel.options === undefined || panel.options.length === 0) { return true; }
  const selectionCount = panel.options.reduce(
    (selected, option) => selected += option.selected ? 1 : 0
    , 0
  );
  const verified = selectionCount >= panel.minimum;
  if (verified) {
    panel.error = null;
  } else {
    const errorMessage = I18n.t('wizard.minimum_options', { minimum: panel.minimum });
    panel.error = errorMessage;
  }
  return verified;
};

const restore = function () {
  _summary = false;
  _activeIndex = 0;
  updateActivePanels();
  _wizardKey = null;
  setPanels([]);
  _panels[0].options.forEach(option => option.selected = false);
  return WizardStore.emitChange();
};

// Store
const WizardStore = Flux.createStore(
  {
    getPanels() {
      return $.extend([], _panels, true);
    },
    getWizardKey() {
      return _wizardKey;
    },
    getSummary() {
      return _summary;
    },
    getAnswers() {
      const answers = [];
      _panels.forEach((panel, i) => {
        if (i === _panels.length - 1) { return; }
        const answer = { title: panel.title, selections: [] };
        if (panel.options !== undefined && panel.options.length > 0) {
          panel.options.map((option) => {
            if (option.selected) { return answer.selections.push(option.title); }
            return undefined;
          });
          if (answer.selections.length === 0) { answer.selections = ['No selections']; }
        }
        return answers.push(answer);
      });
      return answers;
    },
    getOutput() {
      let output = [];
      const logic = [];
      const tags = [];
      _panels.forEach((panel) => {
        if ($.isArray(panel.output)) {
          output = output.concat(panel.output);
        } else {
          output.push(panel.output);
        }
        if (panel.options !== undefined && panel.options.length > 0) {
          return panel.options.forEach((option) => {
            if (!option.selected) { return; }
            if (option.output) {
              if ($.isArray(option.output)) {
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
    }
  }

  , (payload) => {
    const { data } = payload;
    switch (payload.actionType) {
      case 'RECEIVE_WIZARD_INDEX':
        setIndex(data.wizard_index);
        break;
      case 'RECEIVE_WIZARD_PANELS':
        setPanels(data.wizard_panels);
        break;
      case 'SELECT_OPTION':
        selectOption(data.panel_index, data.option_index);
        break;
      case 'EXPAND_OPTION':
        expandOption(data.panel_index, data.option_index);
        break;
      case 'WIZARD_ADVANCE':
        moveWizard();
        break;
      case 'WIZARD_REWIND':
        moveWizard(true, data.toIndex);
        break;
      case 'WIZARD_RESET': case 'WIZARD_SUBMITTED':
        restore();
        // split off /wizard, go back to timeline and reload course
        window.location = `/${window.location.pathname.split('/').splice(1, 4).join('/')}`;
        break;
      default:
      // no default
    }
    return true;
  }
);

export default WizardStore;
