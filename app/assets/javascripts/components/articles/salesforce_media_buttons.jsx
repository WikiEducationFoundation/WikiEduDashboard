import React from 'react';
import PropTypes from 'prop-types';

const SalesforceMediaButtons = ({
  article,
  course,
  editors,
  before_rev_id,
  after_rev_id
}) => {
  const salesforceMediaUrlRoot = '/salesforce/create_media?';
  const courseParam = `course_id=${course.id}`;
  const articleParam = `&article_id=${article.id}`;
  // eslint-disable-next-line
  const diffParams = `&before_rev_id=${before_rev_id}&after_rev_id=${after_rev_id}`;
  const urlWithoutUsername = salesforceMediaUrlRoot + courseParam + articleParam + diffParams;

  const salesforceButtons = editors.map(username => {
    const usernameParam = `&username=${username}`;
    const completeUrl = urlWithoutUsername + usernameParam;
    return (
      <a
        href={completeUrl}
        target="_blank"
        className="button dark small"
        key={`salesforce-media-${username}`}
      >
        {username}
      </a>
    );
  });

  return (
    <div>
      <p>
        Create a new Salesforce &quot;Media&quot; record for this article, credited to:
      </p>
      {salesforceButtons}
    </div>
  );
};

SalesforceMediaButtons.propTypes = {
  article: PropTypes.object,
  course: PropTypes.object,
  editors: PropTypes.array,
  before_rev_id: PropTypes.number,
  after_rev_id: PropTypes.number
};

export default SalesforceMediaButtons;
