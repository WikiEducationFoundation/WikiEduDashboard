import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TransitionGroup from 'react-transition-group/CSSTransitionGroup';

import Panel from './panel.jsx';
import FormPanel from './form_panel.jsx';
import SummaryPanel from './summary_panel.jsx';
import Modal from '../common/modal.jsx';
import WizardActions from '../../actions/wizard_actions.js';
import WizardStore from '../../stores/wizard_store.js';
import { updateCourse, persistCourse } from '../../actions/course_actions_redux';
import { fetchWizardIndex, advanceWizard, rewindWizard, selectWizardOption } from '../../actions/wizard_actions';

const getState = () =>
  ({
    summary: WizardStore.getSummary(),
    wizard_id: WizardStore.getWizardKey()
  })
;

const persist = function () {
  window.onbeforeunload = function () {
      return 'Data will be lost if you leave/refresh the page, are you sure?';
  };
  window.history.replaceState({ index: 0 }, 'wizard', '#step1'); // Initial States
  document.title += ' — Step 1';
  window.onpopstate = function (event) { // Listen to changes
    if (event.state) {
      WizardActions.goToWizard(event.state.index);
      document.title = document.title.replace(/\d+$/, event.state.index + 1); // Sync Titles
    }
  };
};

const unloadEvents = function () {
    window.onpopstate = null;
    window.onbeforeunload = null;
};

const Wizard = createReactClass({
  displayName: 'Wizard',
  propTypes: {
    location: PropTypes.object,
    course: PropTypes.object,
    weeks: PropTypes.array,
    open_weeks: PropTypes.number,
    advanceWizard: PropTypes.func.isRequired,
    rewindWizard: PropTypes.func.isRequired,
    panels: PropTypes.array.isRequired
  },
  mixins: [WizardStore.mixin],
  getInitialState() {
    return getState();
  },
  componentWillMount() {
    persist();
    return this.props.fetchWizardIndex();
  },
  componentWillUnmount() {
    unloadEvents();
    return WizardActions.resetWizard();
  },
  storeDidChange() {
    return this.setState(getState());
  },
  timelinePath() {
    const routes = this.props.location.pathname.split('/');
    routes.pop();
    return routes.join('/');
  },
  render() {
    console.log(this.props.panels)
    const panelCount = this.props.panels.length;
    const panels = this.props.panels.map((panel, i) => {
      const active = this.props.activePanelIndex === i;
      const stepNumber = i + 1;
      let outOf;
      if (i > 1) {
        outOf = ` of ${panelCount}`;
      } else {
        outOf = '';
      }
      const step = `Step ${stepNumber}${outOf}`;
      if (i === 0) {
        return (
          <FormPanel
            panel={panel}
            active={active}
            panelCount={panelCount}
            course={this.props.course}
            key={panel.key}
            index={i}
            step={step}
            weeks={this.props.weeks.length}
            summary={this.state.summary}
            updateCourse={this.props.updateCourse}
            persistCourse={this.props.persistCourse}
            advance={this.props.advanceWizard}
            rewindWizard={this.props.rewindWizard}
            selectWizardOption={this.props.selectWizardOption}
          />
        );
      } else if (i !== 0 && i < panelCount - 1) {
        return (
          <Panel
            panel={panel}
            active={active}
            panelCount={panelCount}
            parentPath={this.timelinePath()}
            key={panel.key}
            index={i}
            step={step}
            summary={this.state.summary}
            open_weeks={this.props.open_weeks}
            course={this.props.course}
            advance={this.props.advanceWizard}
            rewindWizard={this.props.rewindWizard}
            selectWizardOption={this.props.selectWizardOption}
          />
        );
      }
      return (
        <SummaryPanel
          panel={panel}
          active={active}
          parentPath={this.timelinePath()}
          panelCount={panelCount}
          course={this.props.course}
          key={panel.key}
          index={i}
          step={step}
          courseId={this.props.course.slug}
          wizardId={this.state.wizard_id}
          advance={this.props.advanceWizard}
          rewindWizard={this.props.rewindWizard}
          selectWizardOption={this.props.selectWizardOption}
        />
      );
    });

    return (
      <Modal>
        <TransitionGroup
          transitionName="wizard__panel"
          component="div"
          transitionEnterTimeout={500}
          transitionLeaveTimeout={500}
        >
          {panels}
        </TransitionGroup>
      </Modal>
    );
  }
}
);

const mapStateToProps = state => ({
  summary: state.wizard.summary,
  panels: state.wizard.panels,
  wizardId: state.wizard.wizardKey,
  activePanelIndex: state.wizard.activeIndex
});

const mapDispatchToProps = {
  updateCourse,
  persistCourse,
  fetchWizardIndex,
  advanceWizard,
  rewindWizard,
  selectWizardOption
};

export default connect(mapStateToProps, mapDispatchToProps)(Wizard);
