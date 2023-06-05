import React, { useState } from 'react';
import PropTypes from 'prop-types';
import processes from '@components/overview/my_articles/step_processes';

import Step from './Step/Step.jsx';
import NavigationElements from './NavigationElements/NavigationElements';

const ProgressTracker = ({ assignment, course }) => {
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
