import React from 'react';
import PropTypes from 'prop-types';

export const AssignedToLink = ({ name, members }) => {
  if (!members) return null;

  const label = <span key="label">{I18n.t(`assignments.${name}`)}: </span>;
  const list = [...members].sort((a, b) => a > b);
  const links = list.map((username, index, collection) => {
    return (
      <span key={username}>
        <a href={`/users/${username}`}>
          {username}
        </a>
        {index < collection.length - 1 ? ', ' : null}
      </span>
    );
  });

  return [label].concat(links);
};

AssignedToLink.propTypes = {
  // props
  name: PropTypes.string.isRequired,
  members: PropTypes.arrayOf(PropTypes.string)
};

export default AssignedToLink;
