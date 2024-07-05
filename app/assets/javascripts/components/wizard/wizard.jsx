import React, { useEffect } from 'react';
import { connect } from 'react-redux';
import TransitionGroup from '../common/css_transition_group';
import { useLocation } from 'react-router-dom';

import Panel from './panel.jsx';
import FormPanel from './form_panel.jsx';
import SummaryPanel from './summary_panel.jsx';
import Modal from '../common/modal.jsx';

import {
  updateCourse,
  persistCourse
} from '../../actions/course_actions';
import {
  fetchWizardIndex,
  advanceWizard,
  goToWizard,
  selectWizardOption,
  submitWizard
} from '../../actions/wizard_actions';

const persist = (goToWizardFunc) => {
  window.onbeforeunloadcache = window.onbeforeunload;
  window.onbeforeunload = () => 'Data will be lost if you leave/refresh the page, are you sure?';
  window.history.replaceState({ index: 0 }, 'wizard', '#step1');
  document.title += ' — Step 1';
  window.onpopstate = (event) => {
    if (event.state) {
      goToWizardFunc(event.state.index);
      document.title = document.title.replace(/\d+$/, event.state.index + 1);
    }
  };
};

const unloadEvents = () => {
  window.onpopstate = null;
  window.onbeforeunload = window.onbeforeunloadcache;
};

const Wizard = ({
  course,
  weeks,
  open_weeks,
  advanceWizard: advanceWizardAction,
  goToWizard: goToWizardAction,
  panels,
  isValid: isValidProp,
  fetchWizardIndex: fetchWizardIndexAction,
  activePanelIndex,
  summary,
  updateCourse: updateCourseAction,
  persistCourse: persistCourseAction,
  selectWizardOption: selectWizardOptionAction,
  submitWizard: submitWizardAction
}) => {
  const location = useLocation();

  useEffect(() => {
    persist(goToWizardAction);
    fetchWizardIndexAction();
    return () => unloadEvents();
  }, [goToWizardAction, fetchWizardIndexAction]);

  useEffect(() => {
    try {
      document.querySelector('.wizard').scrollTo({ top: 0, behavior: 'smooth' });
    } catch (_err) {
      // eslint-disable-next-line no-console
      console.log('scrollTo not supported');
    }
  }, [activePanelIndex]);

  const timelinePath = () => {
    const routes = location.pathname.split('/');
    routes.pop();
    return routes.join('/');
  };

  const panelCount = panels.length;
  const renderedPanels = panels.map((panel, i) => {
    const active = activePanelIndex === i;
    const stepNumber = i + 1;
    const outOf = i > 1 ? ` of ${panelCount}` : '';
    const step = `Step ${stepNumber}${outOf}`;

    if (i === 0) {
      return (
        <FormPanel
          panel={panel}
          active={active}
          panelCount={panelCount}
          course={course}
          key={panel.key}
          index={i}
          step={step}
          weeks={weeks.length}
          summary={summary}
          updateCourse={updateCourseAction}
          persistCourse={persistCourseAction}
          advance={advanceWizardAction}
          goToWizard={goToWizardAction}
          selectWizardOption={selectWizardOptionAction}
          isValid={isValidProp}
        />
      );
    } else if (i !== 0 && i < panelCount - 1) {
      return (
        <Panel
          panel={panel}
          active={active}
          panelCount={panelCount}
          parentPath={timelinePath()}
          key={panel.key}
          index={i}
          step={step}
          summary={summary}
          open_weeks={open_weeks}
          course={course}
          advance={advanceWizardAction}
          goToWizard={goToWizardAction}
          selectWizardOption={selectWizardOptionAction}
        />
      );
    }
    return (
      <SummaryPanel
        panel={panel}
        panels={panels}
        active={active}
        parentPath={timelinePath()}
        panelCount={panelCount}
        course={course}
        key={panel.key}
        index={i}
        step={step}
        courseId={course.slug}
        submitWizard={submitWizardAction}
        goToWizard={goToWizardAction}
        selectWizardOption={selectWizardOptionAction}
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
        {renderedPanels}
      </TransitionGroup>
    </Modal>
  );
};

const mapStateToProps = state => ({
  summary: state.wizard.summary,
  panels: state.wizard.panels,
  activePanelIndex: state.wizard.activeIndex,
  isValid: state.wizard.isValid
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

export default connect(mapStateToProps, mapDispatchToProps)(Wizard);
