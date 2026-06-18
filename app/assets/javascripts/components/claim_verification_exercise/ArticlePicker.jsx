import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

// The article picker: articles that prior subject-matched courses worked on.
// Each is a client-side link into the viewer (?article_id=N) — no reload. Titles
// are data; the labels are operator-approved copy in the locale namespace.
export const ArticlePicker = ({ articles }) => (
  <div className="container narrow claim-verification-exercise claim-verification-exercise--articles">
    <div className="claim-verification-exercise__intro">
      <h1>{I18n.t('claim_verification.choose_article')}</h1>
    </div>
    {articles.length ? (
      <ul className="claim-verification-exercise__article-list">
        {articles.map(article => (
          <li key={article.id}>
            <Link to={`?article_id=${article.id}`}>{article.title}</Link>
          </li>
        ))}
      </ul>
    ) : (
      // TODO: when there are no candidate articles, render an article-title input
      // so the student can pick one themselves (so this empty case never strands
      // them). Tie in with the claim filtering/prioritization work.
      <p className="claim-verification-exercise__empty">{I18n.t('claim_verification.no_articles')}</p>
    )}
  </div>
);

ArticlePicker.propTypes = {
  articles: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number,
    title: PropTypes.string,
  })).isRequired,
};

export default ArticlePicker;
