import React, { useState, useEffect, useRef } from 'react';
import { includes } from 'lodash-es';

import ArticleViewer from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';

import { fetchStates, ASSIGNED_ROLE, STUDENT_ROLE } from '../../constants';
import { PageAssessmentGrades, ORESSupportedWiki, PageAssessmentSupportedWiki } from '../../utils/article_finder_language_mappings.js';
import ArticleUtils from '../../utils/article_utils.js';

const ArticleFinderRow = (props) => {
    const [isLoading, setIsLoading] = useState(false);
    const prevPropsRef = useRef();

    // Note: This comment is applicable for the article finder row of a course
    // There are two scenarios in which we use isLoading:
    // In the first one, when this.props.assignment is not null, it means the article
    // is assigned. In the second one, when this.props.assignment is undefined, it means
    // that the article is unassigned. When the request to either assign or unassign an
    // article is made, for that time isLoading is set to true and the corresponding
    // button is disabled. On completion of request, this.props.assignment changes and
    // button is enabled again after isLoading is set to false

    useEffect(() => {
      if (isLoading && prevPropsRef.current.assignment !== props.assignment) {
        setIsLoading(false);
      }
      prevPropsRef.current = props;
    }, [isLoading, props.assignment]);

    const assignArticle = (userId = null) => {
        const assignment = {
          title: decodeURIComponent(props.title).trim(),
          project: props.selectedWiki.project,
          language: props.selectedWiki.language,
          course_slug: props.courseSlug,
          user_id: userId,
          role: ASSIGNED_ROLE,
        };
        setIsLoading(true);
        return props.addAssignment(assignment);
    };

    const unassignArticle = (userId = null) => {
        const assignment = {
          article_title: decodeURIComponent(props.title).trim(),
          project: props.assignment.project,
          language: props.assignment.language,
          course_slug: props.courseSlug,
          role: ASSIGNED_ROLE,
          id: props.assignment.id,
          assignment_id: props.assignment.assignment_id,
          user_id: userId,
        };
        setIsLoading(true);
        return props.deleteAssignment(assignment);
    };

    let pageviews;
    if (props.article.fetchState === 'REVISIONSCORE_RECEIVED') {
      pageviews = <div className="results-loading"> &nbsp; &nbsp; </div>;
    }
    if (props.article.pageviews) {
      pageviews = Math.round(props.article.pageviews);
    } else if (props.article.fetchState === 'PAGEVIEWS_RECEIVED') {
      pageviews = <div>{I18n.t('article_finder.page_views_not_found')}</div>;
    }
    let revScore;
    if (
      includes(ORESSupportedWiki.languages, props.selectedWiki.language)
      && includes(ORESSupportedWiki.projects, props.selectedWiki.project)
    ) {
      if (
        props.article.fetchState === 'PAGEASSESSMENT_RECEIVED'
        || props.article.fetchState === 'REVISION_RECEIVED'
      ) {
        revScore = <td><div className="results-loading"> &nbsp; &nbsp; </div></td>;
      } else if (props.article.revScore) {
        revScore = <td className="revScore">{Math.round(props.article.revScore)}</td>;
      } else if (fetchStates[props.article.fetchState] >= fetchStates.REVISIONSCORE_RECEIVED) {
        revScore = <td><div>{I18n.t('article_finder.estimation_score_not_found')}</div></td>;
      } else {
        revScore = <td />;
      }
    }
    let grade;
    if (
      PageAssessmentSupportedWiki[props.selectedWiki.project]
      && includes(PageAssessmentSupportedWiki[props.selectedWiki.project], props.selectedWiki.language)
    ) {
      if (props.article.fetchState === 'TITLE_RECEIVED') {
        grade = <td><div className="results-loading"> &nbsp; &nbsp; </div></td>;
      } else if (props.article.grade) {
        const gradeClass = `rating ${PageAssessmentGrades[props.selectedWiki.project][props.selectedWiki.language][props.article.grade].class}`;
        grade = (
          <td className="tooltip-trigger">
            <div className={gradeClass}><p>{PageAssessmentGrades[props.selectedWiki.project][props.selectedWiki.language][props.article.grade].pretty || '-'}</p></div>
            <div className="tooltip dark">
              <p>{I18n.t(`articles.rating_docs.${PageAssessmentGrades[props.selectedWiki.project][props.selectedWiki.language][props.article.grade].class || '?'}`, { class: props.article.grade || '' })}</p>
            </div>
          </td>
        );
      } else if (fetchStates[props.article.fetchState] >= fetchStates.PAGEASSESSMENT_RECEIVED) {
        grade = (
          <td className="tooltip-trigger">
            <div className="rating null"><p>-</p></div>
            <div className="tooltip dark">
              <p>{I18n.t('articles.rating_docs.?')}</p>
            </div>
          </td>
        );
      } else {
        grade = <td />;
      }
    }
    let button;
    if (props.courseSlug && props.current_user.isAdvancedRole) {
      if (props.assignment) {
        const className = `button small add-available-article ${isLoading ? 'disabled' : ''}`;
        button = (
          <td>
            <button className={className} onClick={() => unassignArticle()}>{I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'remove_article')}`)}</button>
          </td>
        );
      } else {
        const className = `button small add-available-article ${isLoading ? 'disabled' : 'dark'}`;
        button = (
          <td>
            <button className={className} onClick={() => assignArticle()}>{I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'add_available_article')}`)}</button>
          </td>
        );
      }
    } else if (props.courseSlug && props.current_user.role === STUDENT_ROLE) {
      if (props.assignment) {
        const className = `button small add-available-article ${isLoading ? 'disabled' : ''}`;
        button = (
          <td>
            <button className={className} onClick={() => unassignArticle(props.current_user.id)}>{I18n.t(`article_finder.${ArticleUtils.projectSuffix(props.selectedWiki.project, 'unassign_article_self')}`)}</button>
          </td>
        );
      } else {
      const className = `button small add-available-article ${isLoading ? 'disabled' : 'dark'}`;
      button = (
        <td>
          <button className={className} onClick={() => assignArticle(props.current_user.id)}>{I18n.t('article_finder.assign_article_self')}</button>
        </td>
      );
      }
    }
    const article = {
      ...props.article,
      language: props.selectedWiki.language,
      project: props.selectedWiki.project,
      url: `https://${props.selectedWiki.language}.${props.selectedWiki.project}.org/wiki/${props.article.title.replace(/ /g, '_')}`,
    };
    if (props.selectedWiki.project === 'wikidata') {
      delete article.language;
      article.url = `https://${props.selectedWiki.project}.org/wiki/${props.article.title.replace(/ /g, '_')}`;
    }
    const articleViewer = (
      <ArticleViewer
        article={article}
        course={props.course}
        current_user={props.current_user}
        title={props.label ? `${props.label} (${props.article.title})` : props.article.title}
        showArticleFinder={true}
        showPermalink={false}
      />
    );
    return (
      <tr>
        <td>
          {props.article.relevanceIndex}
        </td>
        <td>
          <div className="horizontal-flex">
            {articleViewer}
          </div>
        </td>
        {grade}
        {revScore}
        <td className="pageviews">
          {pageviews}
        </td>
        {button}
      </tr>
    );
};
export default ArticleFinderRow;
