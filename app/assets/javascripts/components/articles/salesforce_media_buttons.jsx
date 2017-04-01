import React from 'react';

const SalesforceMediaButtons = React.createClass({
  displayName: 'SalesforceMediaButtons',

  propTypes: {
    article: React.PropTypes.object,
    course: React.PropTypes.object,
    editors: React.PropTypes.array,
    before_rev_id: React.PropTypes.number,
    after_rev_id: React.PropTypes.number
  },

  render() {
    const salesforceMediaUrlRoot = '/salesforce/create_media?';
    const courseParam = `course_id=${this.props.course.id}`;
    const articleParam = `&article_id=${this.props.article.id}`;
    const diffParams = `&before_rev_id=${this.props.before_rev_id}&after_rev_id=${this.props.after_rev_id}`;
    const urlWithoutUsername = salesforceMediaUrlRoot + courseParam + articleParam + diffParams;

    const salesforceButtons = this.props.editors.map(username => {
      const usernameParam = `&username=${username}`;
      const completeUrl = urlWithoutUsername + usernameParam;
      return (
        <a href={completeUrl} target="_blank" className="button dark small" key={`salesforce-media-${username}`}>
          {username}
        </a>
      );
    });

    return (
      <div>
        <p>
          Create a new Salesforce "Media" record for this article, credited to:
        </p>
        {salesforceButtons}
      </div>
    );
  }
});

export default SalesforceMediaButtons;
