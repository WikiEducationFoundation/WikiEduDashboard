import React from 'react';
import { connect } from 'react-redux';
import { getCampusVolunteerUsers } from '../../selectors';
import InlineUsers from './inline_users.jsx';
import { CAMPUS_VOLUNTEER_ROLE } from '../../constants';

const CampusVolunteers = (props) => {
  return (
    <InlineUsers {...props} users={props.campusVolunteers} role={CAMPUS_VOLUNTEER_ROLE} title="Campus Volunteers" />
  );
};

const mapStateToProps = state => ({
  campusVolunteers: getCampusVolunteerUsers(state)
});

export default connect(mapStateToProps)(CampusVolunteers);
