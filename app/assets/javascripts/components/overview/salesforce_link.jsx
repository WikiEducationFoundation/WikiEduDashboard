import React from 'react';
import PropTypes from 'prop-types';
import { extractSalesforceId } from '../../utils/salesforce_utils.js';

const SalesforceLink = ({
  course,
  current_user,
  linkToSalesforce,
  updateSalesforceRecord
}) => {
  const linkToSalesforceHandler = () => {
    const rawSalesforceId = prompt('Enter the Salesforce record ID or url for this course.');
    if (!rawSalesforceId) { return; }
    const salesforceId = extractSalesforceId(rawSalesforceId);
    if (!salesforceId) {
      alert('That input did not include a valid Salesforce record ID or url.');
      return;
    }
    return linkToSalesforce(course.id, salesforceId);
  };

  const updateSalesforceRecordHandler = () => {
    updateSalesforceRecord(course.id)
      .then(() => alert('updating!'));
  };

  // Render nothing if user isn't an admin, or if Salesforce isn't configured
  if (!current_user.admin || !window.SalesforceServer) {
    return <div />;
  }

  // If Salesforce ID is present, show the admin a link to Salesforce
  // and a button to update the Salesforce record.
  if (course.flags.salesforce_id) {
    const openLink = window.SalesforceServer + course.flags.salesforce_id;
    return (
      <div>
        <div key="link_salesforce" className="available-action"><button onClick={linkToSalesforceHandler} className="button">Update Salesforce ID</button></div>
        <div key="open_salesforce" className="available-action"><a href={openLink} className="button" target="_blank">Open in Salesforce</a></div>
        <div key="update_salesforce" className="available-action"><button onClick={updateSalesforceRecordHandler} className="button" target="_blank">Update Salesforce record</button></div>
      </div>
    );
  }

  // If no Salesforce ID is present, show the "Link to Salesforce" button
  return (
    <p key="link_salesforce"><button onClick={linkToSalesforceHandler} className="button">Link to Salesforce</button></p>
  );
};

SalesforceLink.propTypes = {
  course: PropTypes.object,
  current_user: PropTypes.object,
  linkToSalesforce: PropTypes.func.isRequired,
  updateSalesforceRecord: PropTypes.func.isRequired
};

export default SalesforceLink;
