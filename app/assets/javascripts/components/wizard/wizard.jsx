import React from 'react';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TransitionGroup from '../common/css_transition_group';
import withRouter from '../util/withRouter';

import Panel from './panel.jsx';
import FormPanel from './form_panel.jsx';
import SummaryPanel from './summary_panel.jsx';
import Modal from '../common/modal.jsx';
import { updateCourse, persistCourse } from '../../actions/course_actions';
import { fetchWizardIndex, advanceWizard, goToWizard, selectWizardOption, submitWizard } from '../../actions/wizard_actions';
import { isValid } from '../../selectors';

const persist = function (goToWizardFunc) {
  window.onbeforeunloadcache = window.onbeforeunload;
  window.onbeforeunload = function () {
    return 'Data will be lost if you leave/refresh the page, are you sure?';
  };
  window.history.replaceState({ index: 0 }, 'wizard', '#step1'); // Initial States
  document.title += ' — Step 1';
  window.onpopstate = function (event) { // Listen to changes
    if (event.state) {
      goToWizardFunc(event.state.index);
      document.title = document.title.replace(/\d+$/, event.state.index + 1); // Sync Titles
    }
  };
};

const unloadEvents = function () {
  window.onpopstate = null;
  window.onbeforeunload = window.onbeforeunloadcache;
};

const Wizard = createReactClass({
  displayName: 'Wizard',
  propTypes: {
    location: PropTypes.object,
    course: PropTypes.object,
    weeks: PropTypes.array,
    open_weeks: PropTypes.number,
    advanceWizard: PropTypes.func.isRequired,
    goToWizard: PropTypes.func.isRequired,
    panels: PropTypes.array.isRequired,
    isValid: PropTypes.bool.isRequired
  },

  componentDidMount() {
    persist(this.props.goToWizard);
    return this.props.fetchWizardIndex();
  },

  componentDidUpdate(prevProps) {
    if (prevProps.activePanelIndex === this.props.activePanelIndex) { return; }
    try {
      document.querySelector('.wizard').scrollTo({ top: 0, behavior: 'smooth' });
    } catch (_err) {
      // eslint-disable-next-line no-console
      console.log('scrollTo not supported');
    }
  },

  componentWillUnmount() {
    unloadEvents();
  },
  timelinePath() {
    const routes = this.props.router.location.pathname.split('/');
    routes.pop();
    return routes.join('/');
  },
  render() {
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
            summary={this.props.summary}
            updateCourse={this.props.updateCourse}
            persistCourse={this.props.persistCourse}
            advance={this.props.advanceWizard}
            goToWizard={this.props.goToWizard}
            selectWizardOption={this.props.selectWizardOption}
            isValid={this.props.isValid}
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
            summary={this.props.summary}
            open_weeks={this.props.open_weeks}
            course={this.props.course}
            advance={this.props.advanceWizard}
            goToWizard={this.props.goToWizard}
            selectWizardOption={this.props.selectWizardOption}
          />
        );
      }
      return (
        <SummaryPanel
          panel={panel}
          panels={this.props.panels}
          active={active}
          parentPath={this.timelinePath()}
          panelCount={panelCount}
          course={this.props.course}
          key={panel.key}
          index={i}
          step={step}
          courseId={this.props.course.slug}
          submitWizard={this.props.submitWizard}
          goToWizard={this.props.goToWizard}
          selectWizardOption={this.props.selectWizardOption}
        />
      );
    });

    return (
      <Modal>
        <TransitionGroup
          classNames="wizard__panel"
          component="div"
          timeout={500}
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
  activePanelIndex: state.wizard.activeIndex,
  isValid: isValid(state)
});

const mapDispatchToProps = {
  updateCourse,
  persistCourse,
  fetchWizardIndex,
  advanceWizard,
  goToWizard,
  selectWizardOption,
  submitWizard
};

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Wizard));
