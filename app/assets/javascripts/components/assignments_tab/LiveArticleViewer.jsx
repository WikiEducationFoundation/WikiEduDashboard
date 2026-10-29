import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import ArticleViewer from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';
import { fetchArticleDetails } from '@actions/article_actions';
import { getCurrentUser } from '../../selectors';

// The live article in the article viewer, for an article the student has
// edited: as on the Students tab, their edits are highlighted first, then the
// other course editors' (loaded when it opens). Nothing for an article they
// haven't edited; its title already links to it. No ?showArticle= permalink,
// which would replace the tab's own query string.
const LiveArticleViewer = ({ article, username, renderOpener }) => {
  const course = useSelector(state => state.course);
  const currentUser = useSelector(getCurrentUser);
  const editors = useSelector(state => state.articleDetails[article.article_id]?.editors);
  const dispatch = useDispatch();
  // Built once: the viewer resolves a redirect by retitling this object in place.
  const viewerArticle = useMemo(() => ({
    id: article.article_id, mw_page_id: article.mw_page_id, title: article.title,
    url: article.url, language: article.language, project: article.project,
  }), [article.article_id]);

  if (!article.article_id || !article.stats.revisions) { return null; }
  return (
    <ArticleViewer
      article={viewerArticle} course={course} current_user={currentUser}
      users={editors} assignedUsers={[username]} showPermalink={false}
      fetchArticleDetails={() => dispatch(fetchArticleDetails(article.article_id, course.id))}
      showButtonClass="assignments-tab__viewer-opener" renderOpener={renderOpener}
    />
  );
};

LiveArticleViewer.propTypes = {
  article: PropTypes.object.isRequired,
  username: PropTypes.string.isRequired,
  renderOpener: PropTypes.func,
};

export default LiveArticleViewer;
