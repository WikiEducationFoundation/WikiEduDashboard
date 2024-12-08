import React from 'react';
import PropTypes from 'prop-types';
import AssignedToLink from '@components/overview/my_articles/common/AssignedToLink.jsx';

export const GroupMembersLink = ({ members, course }) => {
  return <AssignedToLink members={members} course={course} name="group_members" />;
};

GroupMembersLink.propTypes = {
  // props
  members: PropTypes.array,
};

export default GroupMembersLink;
