import React from 'react';
import PropTypes from 'prop-types';

import ClaimVerificationViewer from '@components/common/ArticleViewer/containers/ClaimVerificationViewer.jsx';
import { toWikiDomain } from '../../utils/wiki_utils';
import formatRevisionDate from '../../utils/format_revision_date';

// The article picker: each candidate is an (article, flagged-revision) tile from
// the pre-harvested claim pool, and is its own ArticleViewer laid out in a compact
// grid. The viewer's closed state IS the tile — passed in as `renderOpener` — so
// clicking a tile opens the article (at the flagged revision, with its harvested
// claims highlighted) in place and closing it returns to the grid, with no
// separate single-article view to get stranded on. This mirrors the Articles tab,
// where every row carries its own viewer. Titles are data; the heading is
// operator-approved copy in the claim_verification locale namespace.
//
// The per-tile wiki domain is shown only when the candidates span more than one
// wiki. With a single wiki (the common case) it would repeat on every tile, so it
// is omitted as noise.
//
// The shell's `?showArticle=` deep link is article-keyed; when one article has
// several flagged-revision tiles we auto-open the first of them on a deep link.
export const ArticlePicker = ({ articles, course, onTaken, showArticleId }) => {
  const showWiki = new Set(articles.map(toWikiDomain)).size > 1;
  const deepLinkedTile = articles.find(article => article.id === showArticleId);

  return (
    <div className="container narrow claim-verification-exercise claim-verification-exercise--articles">
      <div className="claim-verification-exercise__intro">
        <h1>{I18n.t('claim_verification.choose_article')}</h1>
      </div>
      {articles.length ? (
        <ul className="claim-verification-exercise__article-grid">
          {articles.map(article => (
            <li key={`${article.id}-${article.mw_rev_id}`}>
              <ClaimVerificationViewer
                article={article}
                course={course}
                onTaken={onTaken}
                initialRevisionId={article.mw_rev_id}
                showOnMount={article === deepLinkedTile}
                renderOpener={({ open }) => (
                  <button
                    type="button"
                    className="claim-verification-exercise__article-tile"
                    onClick={open}
                  >
                    <span className="claim-verification-exercise__article-title">{article.title}</span>
                    {article.mw_rev_timestamp && (
                      <span className="claim-verification-exercise__article-date">
                        {I18n.t('claim_verification.tile_revision_date', {
                          date: formatRevisionDate(article.mw_rev_timestamp)
                        })}
                      </span>
                    )}
                    {showWiki && (
                      <span className="claim-verification-exercise__article-wiki">{toWikiDomain(article)}</span>
                    )}
                  </button>
                )}
              />
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
};

ArticlePicker.propTypes = {
  articles: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.number,
    mw_rev_id: PropTypes.number,
    mw_rev_timestamp: PropTypes.string,
    title: PropTypes.string,
    language: PropTypes.string,
    project: PropTypes.string,
  })).isRequired,
  course: PropTypes.object.isRequired,
  onTaken: PropTypes.func.isRequired,
  // Article id from the ?showArticle= deep link, if any; auto-opens that tile.
  showArticleId: PropTypes.number,
};

export default ArticlePicker;
