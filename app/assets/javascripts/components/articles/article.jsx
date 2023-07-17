import React, { useState } from 'react';
import PropTypes from 'prop-types';
import CourseUtils from '../../utils/course_utils.js';
import ArticleViewer from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';
import DiffViewer from '../revisions/diff_viewer.jsx';
import ArticleGraphs from './article_graphs.jsx';
import Switch from 'react-switch';
import { toWikiDomain } from '../../utils/wiki_utils.js';
import { stringify } from 'query-string';

const Article = ({ article, index, course, fetchArticleDetails, updateArticleTrackedStatus, articleDetails, wikidataLabel,
  showOnMount, setSelectedIndex, lastIndex, selectedIndex, pageLogsMessage, deletedMessage, current_user }) => {
  const [tracked, setTracked] = useState(article.tracked);

  const fetchMissingArticleDetails = () => {
    if (!articleDetails) {
      fetchArticleDetails(article.id, course.id);
    }
  };

  const handleTrackedChange = (checked) => {
    updateArticleTrackedStatus(article.id, course.id, checked);
    setTracked(checked);
  };

  const ratingClass = `rating ${article.rating}`;
  const ratingMobileClass = `${ratingClass} tablet-only`;
  const isDeleted = article.deleted;
  const wiki = {
    language: article.language,
    project: article.project
  };
  const pageLogURL = `https://${toWikiDomain(wiki)}/wiki/Special:Log?${stringify({
    page: article.title
  })}`;
  // Uses Course Utils Helper
  const formattedTitle = CourseUtils.formattedArticleTitle(article, course.home_wiki, wikidataLabel);
  const historyUrl = `${article.url}?action=history`;

  const trackedEditable = current_user && current_user.isAdvancedRole;

  let trackedComponent;
  if (course.type !== 'ClassroomProgramCourse' && trackedEditable) {
    trackedComponent = (
      <td className="tracking">
        <Switch onChange={handleTrackedChange} checked={tracked} onColor="#676eb4" />
      </td>
    );
  }

  let contentAdded;
  if (course.home_wiki_bytes_per_word) {
    const wordsAdded = Math.round(article.character_sum / course.home_wiki_bytes_per_word);
    contentAdded = <td className="desktop-only-tc">{wordsAdded}</td>;
  } else {
    contentAdded = <td className="desktop-only-tc">{article.character_sum}</td>;
  }

  const { project, title } = article;
  let { language } = article;
  if (project === 'wikidata') language = 'www';
  const pageviewUrl = `https://pageviews.toolforge.org/?project=${language}.${project}.org&platform=all-access&agent=user&range=latest-90&pages=${title}`;

  const isWikipedia = project === 'wikipedia';

  return (
    <tr className={`article ${isDeleted ? 'deleted' : ' '}`}>
      <td className="tooltip-trigger desktop-only-tc">
        {isWikipedia && <p className="rating_num hidden">{article.rating_num}</p>}
        {isWikipedia && <div className={ratingClass}><p>{!isDeleted ? (article.pretty_rating || '-') : 'DE'}</p></div>}
        {isWikipedia && <div className="tooltip dark">
          <p>
            {
              !isDeleted ? I18n.t(`articles.rating_docs.${article.rating || '?'}`, { class: article.rating || '' }) : deletedMessage
            }
          </p>
          {/* eslint-disable-next-line */}
        </div>}
      </td>
      <td>
        {isWikipedia && <div className={ratingMobileClass}><p>{!isDeleted ? (article.pretty_rating || '-') : 'DE'}</p></div>}
        {isWikipedia && <div />}
        <div className="title">
          <a href={article.url} target="_blank" className="inline">{formattedTitle} {(article.new_article ? ` ${I18n.t('articles.new')}` : '')}</a>
          <br />
          {!isDeleted
            ? (
              <small>
                <a href={historyUrl} target="_blank" className="inline">{I18n.t('articles.history')}</a> | <ArticleGraphs article={article} />
              </small>
            )
            : (
              <small>
                <a href={pageLogURL} target="_blank" className="inline">{pageLogsMessage}</a>
              </small>
            )
          }
        </div>
      </td>
      {contentAdded}
      <td className="desktop-only-tc">{article.references_count || ''}</td>
      <td className="desktop-only-tc">
        <a href={pageviewUrl} target="_blank" className="inline">{article.view_count}</a>
      </td>
      <td>
        <ArticleViewer
          article={article}
          course={course}
          current_user={current_user}
          users={articleDetails && articleDetails.editors}
          fetchArticleDetails={fetchMissingArticleDetails}
          showButtonClass="pull-left"
          showOnMount={showOnMount}
        />
        <DiffViewer
          fetchArticleDetails={fetchMissingArticleDetails}
          index={index}
          revision={articleDetails && articleDetails.last_revision}
          first_revision={articleDetails && articleDetails.first_revision}
          showButtonLabel={I18n.t('articles.show_cumulative_changes')}
          showButtonClass="pull-right"
          editors={articleDetails && articleDetails.editors}
          showSalesforceButton={Boolean(Features.wikiEd && current_user.admin)}
          course={course}
          article={article}
          articleTitle={article.title}
          setSelectedIndex={setSelectedIndex}
          lastIndex={lastIndex}
          selectedIndex={selectedIndex}
        />
      </td>
      {trackedComponent}
    </tr>
  );
};

Article.propTypes = {
  article: PropTypes.object.isRequired,
  index: PropTypes.number,
  course: PropTypes.object.isRequired,
  fetchArticleDetails: PropTypes.func.isRequired,
  updateArticleTrackedStatus: PropTypes.func,
  articleDetails: PropTypes.object,
  wikidataLabel: PropTypes.string,
  showOnMount: PropTypes.bool,
  setSelectedIndex: PropTypes.func,
  lastIndex: PropTypes.number,
  selectedIndex: PropTypes.number,
  deletedMessage: PropTypes.string
};

export default Article;
