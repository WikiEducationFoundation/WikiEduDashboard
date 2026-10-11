import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import ItemLinks from './ItemLinks';
import { itemTitle } from './assignmentHelpers';

// The grader's heading: the assignment, and the way back to the list with this
// assignment's row still open (and its status filter still applied).
const AssignmentHeader = ({ item, backPath }) => (
  <div className="assignments-tab__header">
    <p><Link to={backPath}>← {I18n.t('assignments_tab.label')}</Link></p>
    <h3>{itemTitle(item)}</h3>
    <ItemLinks item={item} withSummary />
  </div>
);

AssignmentHeader.propTypes = {
  item: PropTypes.object.isRequired,
  backPath: PropTypes.string.isRequired,
};

export default AssignmentHeader;
