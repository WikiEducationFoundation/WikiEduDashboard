import React, { useEffect, useRef, useState } from 'react';
import { includes } from 'lodash-es';

import ArticleViewer from '@components/common/ArticleViewer/containers/ArticleViewer.jsx';

import { fetchStates, ASSIGNED_ROLE, STUDENT_ROLE } from '../../constants';
import {
  PageAssessmentGrades,
  ORESSupportedWiki,
  PageAssessmentSupportedWiki,
} from '../../utils/article_finder_language_mappings.js';
import ArticleUtils from '../../utils/article_utils.js';

const ArticleFinderRow = (props) => {
  const {
    addAssignment,
    deleteAssignment,
    article,
    courseSlug,
    current_user,
    assignment,
    selectedWiki,
    title,
    course,
    label,
  } = props;

  const [isLoading, setIsLoading] = useState(false);
  const prevAssingmentProps = useRef(assignment);

  useEffect(() => {
    if (isLoading && assignment !== prevAssingmentProps.current) {
      setIsLoading(false);
    }
  }, [isLoading, assignment, prevAssingmentProps]);

  const assignArticle = (userId = null) => {
    const _assignment = {
      title: decodeURIComponent(title).trim(),
      project: selectedWiki.project,
      language: selectedWiki.language,
      course_slug: courseSlug,
      user_id: userId,
      role: ASSIGNED_ROLE,
    };
    setIsLoading(true);
    return addAssignment(_assignment);
  };

  const unassignArticle = (userId = null) => {
    const _assignment = {
      article_title: decodeURIComponent(title).trim(),
      project: assignment.project,
      language: assignment.language,
      course_slug: courseSlug,
      role: ASSIGNED_ROLE,
      id: assignment.id,
      assignment_id: assignment.assignment_id,
      user_id: userId,
    };
    setIsLoading(true);
    return deleteAssignment(_assignment);
  };

  let pageviews;
  if (article?.fetchState === 'REVISIONSCORE_RECEIVED') {
    pageviews = <div className="results-loading"> &nbsp; &nbsp; </div>;
  } else if (article?.pageviews) {
    pageviews = Math.round(article.pageviews);
  } else if (article.fetchState === 'PAGEVIEWS_RECEIVED') {
    pageviews = <div>Page Views not found!</div>;
  }

  let revScore;
  if (
    includes(ORESSupportedWiki.languages, selectedWiki.language)
    && includes(ORESSupportedWiki.projects, selectedWiki.project)
  ) {
    if (
      article.fetchState === 'PAGEASSESSMENT_RECEIVED'
      || article.fetchState === 'REVISION_RECEIVED'
    ) {
      revScore = (
        <td>
          <div className="results-loading"> &nbsp; &nbsp; </div>
        </td>
      );
    } else if (article.revScore) {
      revScore = <td className="revScore">{Math.round(article.revScore)}</td>;
    } else if (
      fetchStates[article.fetchState] >= fetchStates.REVISIONSCORE_RECEIVED
    ) {
      revScore = (
        <td>
          <div>Estimation Score not found!</div>
        </td>
      );
    } else {
      revScore = <td />;
    }
  }

  let grade;
  if (
    PageAssessmentSupportedWiki[selectedWiki.project]
    && includes(
      PageAssessmentSupportedWiki[selectedWiki.project],
      selectedWiki.language
    )
  ) {
    if (article.fetchState === 'TITLE_RECEIVED') {
      grade = (
        <td>
          <div className="results-loading"> &nbsp; &nbsp; </div>
        </td>
      );
    } else if (article.grade) {
      const gradeClass = `rating ${
        PageAssessmentGrades[selectedWiki.project][selectedWiki.language][
          article.grade
        ].class
      }`;
      grade = (
        <td className="tooltip-trigger">
          <div className={gradeClass}>
            <p>
              {PageAssessmentGrades[selectedWiki.project][
                selectedWiki.language
              ][article.grade].pretty || '-'}
            </p>
          </div>
          <div className="tooltip dark">
            <p>
              {I18n.t(
                `articles.rating_docs.${
                  PageAssessmentGrades[selectedWiki.project][
                    selectedWiki.language
                  ][article.grade].class || '?'
                }`,
                { class: article.grade || '' }
              )}
            </p>
          </div>
        </td>
      );
    } else if (
      fetchStates[article.fetchState] >= fetchStates.PAGEASSESSMENT_RECEIVED
    ) {
      grade = (
        <td className="tooltip-trigger">
          <div className="rating null">
            <p>-</p>
          </div>
          <div className="tooltip dark">
            <p>{I18n.t('articles.rating_docs.?')}</p>
          </div>
        </td>
      );
    } else {
      grade = <td />;
    }
  }

  const isAdvanced = courseSlug && current_user.isAdvancedRole;
  const isStudent = courseSlug && current_user.role === STUDENT_ROLE;
  const isAssignment = assignment;
  const isAdvancedRoleAndAssignmentPresent = isAdvanced && isAssignment;
  const isAdvancedRoleAndAssignmentAbsent = isAdvanced && !isAssignment;
  const isStudentAndAssignmentPresent = isStudent && isAssignment;
  const isStudentAndAssignmentAbsent = isStudent && !isAssignment;

  let buttonProps;
  if (isAdvancedRoleAndAssignmentPresent) {
    buttonProps = {
      className: `button small add-available-article ${
        isLoading ? 'disabled' : ''
      }`,
      onClick: unassignArticle,
      text: I18n.t(
        `article_finder.${ArticleUtils.projectSuffix(
          selectedWiki.project,
          'remove_article'
        )}`
      ),
    };
  } else if (isAdvancedRoleAndAssignmentAbsent) {
    buttonProps = {
      className: `button small add-available-article ${
        isLoading ? 'disabled' : 'dark'
      }`,
      onClick: assignArticle,
      text: I18n.t(
        `article_finder.${ArticleUtils.projectSuffix(
          selectedWiki.project,
          'add_available_article'
        )}`
      ),
    };
  } else if (isStudentAndAssignmentPresent) {
    buttonProps = {
      className: `button small add-available-article ${
        isLoading ? 'disabled' : ''
      }`,
      onClick: () => unassignArticle(this.current_user.id),
      text: I18n.t(
        `article_finder.${ArticleUtils.projectSuffix(
          selectedWiki.project,
          'unassign_article_self'
        )}`
      ),
    };
  } else if (isStudentAndAssignmentAbsent) {
    buttonProps = {
      className: `button small add-available-article ${
        isLoading ? 'disabled' : 'dark'
      }`,
      onClick: () => assignArticle(this.current_user.id),
      text: I18n.t('article_finder.assign_article_self'),
    };
  }

  const _article = {
    ...article,
    language: selectedWiki.language,
    project: selectedWiki.project,
    url: `https://${selectedWiki.language}.${
      selectedWiki.project
    }.org/wiki/${article.title.replace(/ /g, '_')}`,
  };

  if (selectedWiki.project === 'wikidata') {
    delete _article.language;
    _article.url = `https://${
      selectedWiki.project
    }.org/wiki/${article.title.replace(/ /g, '_')}`;
  }

  return (
    <tr>
      <td>{article.relevanceIndex}</td>
      <td>
        <div className="horizontal-flex">
          <ArticleViewer
            article={_article}
            course={course}
            current_user={current_user}
            title={label ? `${label} (${article.title})` : article.title}
            showArticleFinder={true}
            showPermalink={false}
          />
        </div>
      </td>
      {revScore}
      {grade}
      <td>{pageviews}</td>
      <button className={buttonProps?.className} onClick={buttonProps?.onClick}>
        {buttonProps?.text}
      </button>
    </tr>
  );
};

export default ArticleFinderRow;
