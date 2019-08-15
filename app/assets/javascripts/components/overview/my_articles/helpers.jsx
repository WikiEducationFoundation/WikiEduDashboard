import React from 'react';

// Helper Components
export const Separator = () => <span> •&nbsp;</span>;

export const AssignedToLink = ({ name, members }) => {
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

export const EditorLink = ({ editors }) => {
  return <AssignedToLink members={editors} name="editors" />;
};

export const ReviewerLink = ({ reviewers }) => {
  return <AssignedToLink members={reviewers} name="reviewers" />;
};
