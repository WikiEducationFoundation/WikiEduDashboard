import React from 'react';
import ServerActions from '../../actions/server_actions.js';

const SalesforceLink = React.createClass({
  propTypes: {
    course: React.PropTypes.object,
    current_user: React.PropTypes.object
  },

  linkToSalesforce() {
    const rawSalesforceId = prompt('Enter the Salesforce record ID or url for this course.');
    // Salesforce URLs may look like this: https://cs54.salesforce.com/c1f1f010013YOsu?srPos=2&srKp=a0f
    // We must remove both the server and the query string to extract the ID.
    const salesforceId = rawSalesforceId.replace(SalesforceServer, '').replace(/\?.*/, '');
    ServerActions.linkToSalesforce(this.props.course.id, salesforceId);
  },

  updateSalesforceRecord() {
    ServerActions.updateSalesforceRecord(this.props.course.id)
      .then(alert('updated!'));
  },

  render() {
    // Render nothing if user isn't an admin, or if Salesforce isn't configured
    if (!this.props.current_user.admin || !SalesforceServer) {
      return <div />;
    }
    // If Salesforce ID is present, show the admin a link to Salesforce
    // and a button to update the Salesforce record.
    if (this.props.course.flags.salesforce_id) {
      const openLink = SalesforceServer + this.props.course.flags.salesforce_id;
      return (
        <div>
          <p key="open_salesforce"><a href={openLink} className="button" target="_blank">Open in Salesforce</a></p>
          <p key="update_salesforce"><button onClick={this.updateSalesforceRecord} className="button" target="_blank">Update Salesforce record</button></p>
        </div>
      );
    }
    // If no Salesforce ID is present, show the "Link to Salesforce" buttton
    return (
      <p key="link_salesforce"><button onClick={this.linkToSalesforce} className="button">Link to Salesforce</button></p>
    );
  }
});

export default SalesforceLink;
