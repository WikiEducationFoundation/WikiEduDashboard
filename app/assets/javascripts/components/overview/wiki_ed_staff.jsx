import React from 'react';
import { connect } from "react-redux";
import _ from 'lodash';
import { getFiltered } from '../../utils/model_utils';
import InlineUsers from './inline_users.jsx';

const STAFF_ROLE = 4;
const WikiEdStaff = props => {
  return (
    <InlineUsers {...props} users={props.wikiEdStaff} role={STAFF_ROLE} title="Wiki Ed Staff" />
  );
};

const mapStateToProps = state => ({
  wikiEdStaff: _.sortBy(getFiltered(state.users.users, { role: STAFF_ROLE }), 'enrolled_at')
});

export default connect(mapStateToProps)(WikiEdStaff);
