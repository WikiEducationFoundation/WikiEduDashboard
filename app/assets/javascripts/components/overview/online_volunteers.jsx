import React from 'react';
import { connect } from 'react-redux';
import { getOnlineVolunteerUsers } from '../../selectors';
import InlineUsers from './inline_users.jsx';
import { ONLINE_VOLUNTEER_ROLE } from '../../constants';

const OnlineVolunteers = (props) => {
  return (
    <InlineUsers {...props} users={props.onlineVolunteers} role={ONLINE_VOLUNTEER_ROLE} title="Online Volunteers" />
  );
};

const mapStateToProps = state => ({
  onlineVolunteers: getOnlineVolunteerUsers(state)
});

export default connect(mapStateToProps)(OnlineVolunteers);
