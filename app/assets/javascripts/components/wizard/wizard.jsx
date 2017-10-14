import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Panel from './panel.jsx';
import FormPanel from './form_panel.jsx';
import SummaryPanel from './summary_panel.jsx';

import Modal from '../common/modal.jsx';
import WizardActions from '../../actions/wizard_actions.js';
import ServerActions from '../../actions/server_actions.js';
import WizardStore from '../../stores/wizard_store.js';
import TransitionGroup from 'react-transition-group/CSSTransitionGroup';

const getState = () =>
  ({
    summary: WizardStore.getSummary(),
    panels: WizardStore.getPanels(),
    wizard_id: WizardStore.getWizardKey()
  })
;

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
    return ServerActions.fetchWizardIndex();
  },
  componentWillUnmount() {
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
            course={this.props.course}
            key={panel.key}
            index={i}
            step={step}
            weeks={this.props.weeks.length}
            summary={this.state.summary}
          />
        );
      } else if (i !== 0 && i < panelCount - 1) {
        return (
          <Panel
            panel={panel}
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

export default Wizard;
