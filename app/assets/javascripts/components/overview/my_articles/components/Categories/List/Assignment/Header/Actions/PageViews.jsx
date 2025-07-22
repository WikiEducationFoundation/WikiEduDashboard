import React from 'react';
import PropTypes from 'prop-types';

export const PageViews = ({ article }) => {
  const { language, project, title } = article;
  const pageviewUrl = `https://pageviews.toolforge.org/?project=${language}.${project}.org&platform=all-access&agent=user&range=latest-90&pages=${title}`;
  return (
    <div>
      <a className="button dark small" href={pageviewUrl} target="_blank">Pageviews</a>
    </div>
  );
};

PageViews.propTypes = {
  // props
  article: PropTypes.object.isRequired,
};

export default PageViews;
