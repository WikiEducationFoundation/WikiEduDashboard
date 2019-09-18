import React from 'react';

export default ({ name, members }) => {
  if (!members) return null;

  const label = <span key="label">{I18n.t(`assignments.${name}`)}: </span>;
  const links = members.map((username, index, collection) => {
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
