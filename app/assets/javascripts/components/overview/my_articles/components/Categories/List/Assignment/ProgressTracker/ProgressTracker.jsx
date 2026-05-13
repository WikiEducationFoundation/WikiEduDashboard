import React, { useState } from 'react';
import PropTypes from 'prop-types';
import processes from '@components/overview/my_articles/step_processes';

import Step from './Step/Step.jsx';
import NavigationElements from './NavigationElements/NavigationElements';

const ProgressTracker = ({ assignment, course }) => {
  // Don't render progress tracker for 'no_sandboxes' courses.
  if (!course.progress_tracker_enabled) { return null; }

  const [showTracker, setShowTracker] = useState(false);

  const toggle = () => {
    setShowTracker(prevState => !prevState);
  };

  const steps = processes(assignment, course).map((content, index) => (
    <Step
      {...content}
      assignment={assignment}
      course={course}
      index={index}
      key={index}
    />
  ));

  return (
    <div className="progress-tracker">
      <button
        className="screen-reader"
        onClick={toggle}
      >
        Click to hide or show progress tracker
      </button>
      {/* Keyboard activation is handled by the adjacent .screen-reader
          <button> above (lines 30-35), which is the keyboard-accessible
          surface for this toggle. The <nav> onClick here is mouse-only
          affordance for sighted users clicking the visible progress
          navigation. */}
      {/* eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-noninteractive-element-interactions */}
      <nav
        aria-label="Click to hide or show progress tracker"
        className="toggle-progress-tracker"
        onClick={toggle}
      >
        <NavigationElements assignment={assignment} showTracker={showTracker} course={course} />
      </nav>
      <section className="flow">
        {showTracker ? steps : null}
      </section>
    </div>
  );
};

ProgressTracker.propTypes = {
  assignment: PropTypes.object.isRequired,
  course: PropTypes.object.isRequired,
};

export default ProgressTracker;
