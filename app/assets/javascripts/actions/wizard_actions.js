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
  }
});

export default WizardActions;
