import McFly from 'mcfly';
let Flux            = new McFly();

import ServerActions from '../actions/server_actions.js';

let _active_index = 0;
let _summary = false;
let _wizard_key = null;
let _panels = [{
  title:  I18n.t('wizard.course_dates'),
  description: '',
  active: true,
  options: [],
  type: -1,
  minimum: 0,
  key: 'dates'
},{
  title: I18n.t('wizard.assignment_type'),
  description: I18n.t('wizard.select_assignment'),
  active: false,
  options: [],
  type: 1,
  minimum: 1,
  key: 'index'
},{
  title: I18n.t('wizard.summary'),
  description: I18n.t('wizard.review_selections'),
  active: false,
  options: [],
  type: -1,
  minimum: 0,
  key: 'summary'
}];

// Utilities
let setIndex = function(index) {
  // index of the assignment panel
  _panels[1].options = index;
  return WizardStore.emitChange();
};

let setPanels = function(panels) {
  // 3 hard-coded panels: course dates, assignments, summary
  // _panels.length will change when more are inserted
  let to_remove = _panels.length - 3;
  // insert retrieved panels after hardcoded panels, but before summary
  // also remove if you chose a different assignment but went back
  // 3 (for now) is index of the first to remove (the first retrieved panel)
  _panels.splice.apply(_panels, [2, to_remove].concat(panels));
  if (_active_index > 0) { moveWizard(); }
  return WizardStore.emitChange();
};

let updateActivePanels = function() {
  if (_panels.length > 0) {
    _panels.forEach(panel => panel.active = false);
    return _panels[_active_index].active = true;
  }
};

let selectOption = function(panel_index, option_index, value=true) {
  let panel = _panels[panel_index];
  let option = panel.options[option_index];
  if (panel.type !== 0) {  // multiple choice
    panel.options.forEach(option => option.selected = false);
  }
  option.selected = !(option.selected || false);
  verifyPanelSelections(panel);
  _summary = _summary && !(_active_index === 1 && _summary);
  return WizardStore.emitChange();
};

let expandOption = function(panel_index, option_index) {
  let panel = _panels[panel_index];
  let option = panel.options[option_index];
  option.expanded = !(option.expanded || false);
  return WizardStore.emitChange();
};

var moveWizard = function(backwards=false, to_index=null) {
  let active_panel = _panels[_active_index];
  let increment = backwards ? -1 : 0;

  if (!backwards && verifyPanelSelections(active_panel)) {
    increment = 1;
    if (_active_index === 1) { // assignment step
      let selected_wizard = _.find(_panels[_active_index].options, o => o.selected);
      if (selected_wizard.key !== _wizard_key) {
        _wizard_key = selected_wizard.key;
        ServerActions.fetchWizardPanels(selected_wizard.key);
        increment = 0;
      }
    }
  }

  if (to_index != null) {
    _active_index = to_index;
  } else {
    _active_index += increment;
  }

  if (backwards) { _summary = (to_index != null); }

  if (_active_index === -1) {
    _active_index = 0;
  } else if (_active_index === _panels.length || (_summary && !backwards)) {
    _active_index = _panels.length - 1;
  }

  //####
  // THIS IS CHECK TO SEE IF WE NEED TO SCROLL PANEL TO TOP BEFORE TRANSITION
  // THERE IS PERHAPS A BETTER PLACE THEN THIS FILE TO PUT THIS EVENT/TRANSITION
  //####
  let timeoutTime = increment !== 0 ? 150 : 0;
  if (timeoutTime > 0) {
    if ($('.wizard').scrollTop() > 0) {
      $('.wizard').animate(
        {scrollTop: 0}
      ,timeoutTime);
    }
  }

  return setTimeout(function() {
    updateActivePanels();
    return WizardStore.emitChange();
  }
  ,timeoutTime);
};

var verifyPanelSelections = function(panel) {
  if (panel.options === undefined || panel.options.length === 0) { return true; }
  let selection_count = panel.options.reduce((selected, option) => selected += option.selected ? 1 : 0
  , 0);
  let verified = selection_count >= panel.minimum;
  if (verified) {
    panel.error = null;
  } else {
    let error_message = I18n.t('wizard.minimum_options', { minimum: panel.minimum });
    panel.error = error_message;
  }
  return verified;
};

let restore = function() {
  _summary = false;
  _active_index = 0;
  updateActivePanels();
  _wizard_key = null;
  setPanels([]);
  _panels[0].options.forEach(option => option.selected = false);
  return WizardStore.emitChange();
};

// Store
var WizardStore = Flux.createStore({
  getPanels() {
    return $.extend([], _panels, true);
  },
  getWizardKey() {
    return _wizard_key;
  },
  getSummary() {
    return _summary;
  },
  getAnswers() {
    let answers = [];
    _panels.forEach(function(panel, i) {
      if (i === _panels.length - 1) { return; }
      let answer = { title: panel.title, selections: [] };
      if (panel.options !== undefined && panel.options.length > 0) {
        panel.options.map(function(option) {
          if (option.selected) { return answer.selections.push(option.title); }
        });
        if (answer.selections.length === 0) { answer.selections = ['No selections']; }
      }
      return answers.push(answer);
    });
    return answers;
  },
  getOutput() {
    let output = [];
    let logic = [];
    let tags = [];
    _panels.forEach(function(panel) {
      if ($.isArray(panel.output)) {
        output = output.concat(panel.output);
      } else {
        output.push(panel.output);
      }
      if (panel.options !== undefined && panel.options.length > 0) {
        return panel.options.forEach(function(option) {
          if (!option.selected) { return; }
          if (option.output != null) {
            if ($.isArray(option.output)) {
              output = output.concat(option.output);
            } else {
              output.push(option.output);
            }
          }
          if (option.logic != null) { logic.push(option.logic); }
          if (option.tag != null) { return tags.push({ key: panel.key, tag: option.tag }); }
        });
      }
    });
    return { output, logic, tags };
  }
}

, function(payload) {
  let { data } = payload;
  switch(payload.actionType) {
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
      moveWizard(true, data.to_index);
      break;
    case 'WIZARD_RESET': case 'WIZARD_SUBMITTED':
      restore();
      let loc = window.location.pathname.split('/');
      // split off /wizard, go back to timeline and reload course
      window.location = `/${loc.splice(1, 4).join('/')}`;
      break;
  }
  return true;
});

export default WizardStore;
