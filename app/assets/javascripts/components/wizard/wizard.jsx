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
    location: PropTypes.shape({
      action: PropTypes.string,
      hash: PropTypes.string,
      key: PropTypes.number,
      pathname: PropTypes.string,
      query: PropTypes.shape({}), // might be wrong, but in development this is what I observed
      search: PropTypes.string,
      state: PropTypes.string, // not sure what this needs to be
    }),
    course: PropTypes.shape({
      canUploadSyllabus: PropTypes.bool,
      cloned_status: PropTypes.bool, // might be wrong, but in development this is what I observed
      created_count: PropTypes.string,
      day_exceptions: PropTypes.string,
      description: PropTypes.string,
      edit_count: PropTypes.string,
      edited_count: PropTypes.string,
      end: PropTypes.string,
      ended: PropTypes.bool,
      enroll_url: PropTypes.string,
      error: PropTypes.any, // not sure what this needs to be
      expected_students: PropTypes.number,
      flags: PropTypes.shape({}), // not sure what this needs to be.
      home_wiki: PropTypes.shape({
        id: PropTypes.number,
        language: PropTypes.string,
        project: PropTypes.string
      }),
      id: PropTypes.number,
      legacy: PropTypes.bool,
      level: PropTypes.string,
      no_day_exceptions: PropTypes.bool,
      passcode: PropTypes.string,
      passcode_required: PropTypes.bool,
      published: PropTypes.bool,
      school: PropTypes.string,
      slug: PropTypes.string,
      string_prefix: PropTypes.string,
      student_count: PropTypes.number,
      subject: PropTypes.string,
      submitted: PropTypes.bool,
      survey_notifcations: PropTypes.arrayOf(PropTypes.shape({})),
      term: PropTypes.string,
      timeline_enabled: PropTypes.bool,
      timeline_end: PropTypes.string,
      timeline_start: PropTypes.string,
      title: PropTypes.string,
      trained_count: PropTypes.number,
      type: PropTypes.string,
      updated_at: PropTypes.string,
      upload_count: PropTypes.number,
      upload_usages_count: PropTypes.number,
      uploads_in_use_count: PropTypes.number,
      url: PropTypes.string,
      use_start_and_end_times: PropTypes.bool,
      view_count: PropTypes.string,
      weekdays: PropTypes.string,
      word_count: PropTypes.string,
    }),
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
