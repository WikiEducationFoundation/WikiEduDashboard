import React from 'react';
import PropTypes from 'prop-types';

export const Permalink = ({ articleId }) => (
  <span>
    <a className="icon-link" href={`?showArticle=${articleId}`} aria-label={I18n.t('articles.permalink')} />
  </span>
);

Permalink.propTypes = {
  articleId: PropTypes.number.isRequired
};

export default Permalink;
