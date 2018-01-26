import React from 'react';
import { connect } from "react-redux";
import _ from 'lodash';
import { getFiltered } from '../../utils/model_utils';
import InlineUsers from './inline_users.jsx';

const ONLINE_VOLUNTEER_ROLE = 2;
const OnlineVolunteers = props => {
  return (
    <InlineUsers {...props} users={props.onlineVolunteers} role={ONLINE_VOLUNTEER_ROLE} title="Online Volunteers" />
  );
};

const mapStateToProps = state => ({
  onlineVolunteers: _.sortBy(getFiltered(state.users.users, { role: ONLINE_VOLUNTEER_ROLE }), 'enrolled_at')
});

export default connect(mapStateToProps)(OnlineVolunteers);
