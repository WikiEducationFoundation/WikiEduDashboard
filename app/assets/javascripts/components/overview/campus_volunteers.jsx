import React from 'react';
import { connect } from "react-redux";
import _ from 'lodash';
import { getFiltered } from '../../utils/model_utils';
import InlineUsers from './inline_users.jsx';

const CAMPUS_VOLUNTEER_ROLE = 3;
const CampusVolunteers = props => {
  return (
    <InlineUsers {...props} users={props.campusVolunteers} role={CAMPUS_VOLUNTEER_ROLE} title="Campus Volunteers" />
  );
};

const mapStateToProps = state => ({
  campusVolunteers: _.sortBy(getFiltered(state.users.users, { role: CAMPUS_VOLUNTEER_ROLE }), 'enrolled_at')
});

export default connect(mapStateToProps)(CampusVolunteers);
