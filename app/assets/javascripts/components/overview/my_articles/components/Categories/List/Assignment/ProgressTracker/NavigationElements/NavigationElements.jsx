import React from 'react';
import PropTypes from 'prop-types';

// components
import ListItem from './ListItem';

// helpers
import processes from '@components/overview/my_articles/step_processes';

export const Navigation = ({ assignment, showTracker, course }) => {
  const lis = processes(assignment, course).map((props, i) => (
    <ListItem
      {...props}
      assignment={assignment}
      index={i}
      key={`process-step-${i}`}
    />
  ));

  return (
    <ul>
      {lis}
      {
        showTracker
          ? <li className="icon icon-arrow-reverse table-expandable-indicator limit-size" />
          : <li className="icon icon-arrow table-expandable-indicator limit-size" />
      }
    </ul>
  );
};

Navigation.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
  showTracker: PropTypes.bool.isRequired,
};

export default Navigation;
