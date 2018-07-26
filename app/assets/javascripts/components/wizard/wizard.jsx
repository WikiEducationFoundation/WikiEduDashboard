import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TransitionGroup from 'react-transition-group/CSSTransitionGroup';

import Panel from './panel.jsx';
import FormPanel from './form_panel.jsx';
import SummaryPanel from './summary_panel.jsx';
import Modal from '../common/modal.jsx';
import WizardActions from '../../actions/wizard_actions.js';
import ServerActions from '../../actions/server_actions.js';
import WizardStore from '../../stores/wizard_store.js';
import { updateCourse } from '../../actions/course_actions_redux';

const getState = () =>
  ({
    summary: WizardStore.getSummary(),
    panels: WizardStore.getPanels(),
    wizard_id: WizardStore.getWizardKey()
  })
;

const persist = function () {
  window.onbeforeunload = function () {
      return "Data will be lost if you leave/refresh the page, are you sure?";
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
    open_weeks: PropTypes.number
  },
  mixins: [WizardStore.mixin],
  getInitialState() {
    return getState();
  },
  componentWillMount() {
    persist();
    return ServerActions.fetchWizardIndex();
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
    const panels = this.state.panels.map((panel, i) => {
      const panelCount = this.state.panels.length;
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
            panelCount={panelCount}
            course={this.props.course}
            key={panel.key}
            index={i}
            step={step}
            weeks={this.props.weeks.length}
            summary={this.state.summary}
            updateCourse={this.props.updateCourse}
          />
        );
      } else if (i !== 0 && i < panelCount - 1) {
        return (
          <Panel
            panel={panel}
            panelCount={panelCount}
            parentPath={this.timelinePath()}
            key={panel.key}
            index={i}
            step={step}
            summary={this.state.summary}
            open_weeks={this.props.open_weeks}
            course={this.props.course}
          />
        );
      }
      return (
        <SummaryPanel
          panel={panel}
          parentPath={this.timelinePath()}
          panelCount={panelCount}
          course={this.props.course}
          key={panel.key}
          index={i}
          step={step}
          courseId={this.props.course.slug}
          wizardId={this.state.wizard_id}
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

const mapDispatchToProps = {
  updateCourse
};

export default connect(null, mapDispatchToProps)(Wizard);
