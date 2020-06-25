import React from 'react';
import PropTypes from 'prop-types';

// components
import ListItem from './ListItem';

// helpers
import processes from '@components/overview/my_articles/step_processes';

export const Navigation = ({ assignment, show, course }) => {
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
      { lis }
      {
        show
          ? <li className="icon icon-arrow-reverse table-expandable-indicator limit-size" />
          : <li className="icon icon-arrow table-expandable-indicator limit-size" />
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
