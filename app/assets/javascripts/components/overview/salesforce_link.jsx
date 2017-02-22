import React from 'react';

const SalesforceLink = React.createClass({
  propTypes: {
    course: React.PropTypes.object,
    current_user: React.PropTypes.object
  },

  render() {
    // Render nothing if user isn't an admin or course lacks a Salesforce ID.
    if (!this.props.current_user.admin || !this.props.course.flags.salesforce_id) {
      return <div />;
    }
    const link = SalesforceServer + this.props.course.flags.salesforce_id;
    return (
      <div><a href={link} target="_blank">Salesforce record</a></div>
    );
  }
});

export default SalesforceLink;
