import React from 'react';
import PropTypes from 'prop-types';

export const ListItem = ({ assignment, index, status, title }) => (
  <li className={assignment.assignment_status === status ? 'selected' : ''}>
    {`${index + 1}. ${title}`}
  </li>
);

ListItem.propTypes = {
  // props
  assignment: PropTypes.object.isRequired,
  index: PropTypes.number.isRequired,
  status: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
};

export default ListItem;
