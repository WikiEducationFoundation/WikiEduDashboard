import React from 'react';
import PropTypes from 'prop-types';

// components
import ListItem from './ListItem';

// helpers
import processes from '../../../../../../step_processes';

export const Navigation = ({ assignment, show }) => {
  console.log(assignment);
  const lis = processes(assignment).map((props, i) => (
    <ListItem
      {...props}
      assignment={assignment}
      index={i}
      key={`process-step-${i}`}
    />
  ));

  return (
    <ul>
      { lis }
      {
        show
          ? <li aria-label="Close Progress Tracker" className="icon icon-arrow-reverse table-expandable-indicator" />
          : <li aria-label="Show Progress Tracker" className="icon icon-arrow table-expandable-indicator" />
      }
    </ul>
  );
};

Navigation.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
  show: PropTypes.bool.isRequired,
};

export default Navigation;
