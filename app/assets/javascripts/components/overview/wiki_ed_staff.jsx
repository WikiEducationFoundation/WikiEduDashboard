import React from 'react';
import { connect } from 'react-redux';
import { getStaffUsers } from '../../selectors';
import InlineUsers from './inline_users.jsx';
import { STAFF_ROLE } from '../../constants';

const WikiEdStaff = (props) => {
  return (
    <InlineUsers {...props} users={props.wikiEdStaff} role={STAFF_ROLE} title="Wiki Ed Staff" />
  );
};

const mapStateToProps = state => ({
  wikiEdStaff: getStaffUsers(state)
});

export default connect(mapStateToProps)(WikiEdStaff);
