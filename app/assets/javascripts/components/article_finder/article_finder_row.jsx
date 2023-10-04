import React, { useEffect, useMemo, useRef, useState } from 'react';
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

  const pageviews = () => {
    if (article.fetchState === 'REVISIONSCORE_RECEIVED') {
      return <div className="results-loading"> &nbsp; &nbsp; </div>;
    }
    if (article.pageviews) {
      return Math.round(article.pageviews);
    } else if (article.fetchState === 'PAGEVIEWS_RECEIVED') {
      return <div>Page Views not found!</div>;
    }
  };

  const revScore = () => {
    if (
      includes(ORESSupportedWiki.languages, selectedWiki.language)
      && includes(ORESSupportedWiki.projects, selectedWiki.project)
    ) {
      if (
        article.fetchState === 'PAGEASSESSMENT_RECEIVED'
        || article.fetchState === 'REVISION_RECEIVED'
      ) {
        return (
          <td>
            <div className="results-loading"> &nbsp; &nbsp; </div>
          </td>
        );
      } else if (article.revScore) {
        return <td className="revScore">{Math.round(article.revScore)}</td>;
      } else if (
        fetchStates[article.fetchState] >= fetchStates.REVISIONSCORE_RECEIVED
      ) {
        return (
          <td>
            <div>Estimation Score not found!</div>
          </td>
        );
      }
      return <td />;
    }
  };

  const grade = () => {
    if (
      PageAssessmentSupportedWiki[selectedWiki.project]
      && includes(
        PageAssessmentSupportedWiki[selectedWiki.project],
        selectedWiki.language
      )
    ) {
      if (article.fetchState === 'TITLE_RECEIVED') {
        return (
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
        return (
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
        return (
          <td className="tooltip-trigger">
            <div className="rating null">
              <p>-</p>
            </div>
            <div className="tooltip dark">
              <p>{I18n.t('articles.rating_docs.?')}</p>
            </div>
          </td>
        );
      }
      return <td />;
    }
  };

  const isAdvanced = courseSlug && current_user.isAdvancedRole;
  const isStudent = courseSlug && current_user.role === STUDENT_ROLE;
  const isAssignment = assignment;
  const isAdvancedRoleAndAssignmentPresent = isAdvanced && isAssignment;
  const isAdvancedRoleAndAssignmentAbsent = isAdvanced && !isAssignment;
  const isStudentAndAssignmentPresent = isStudent && isAssignment;
  const isStudentAndAssignmentAbsent = isStudent && !isAssignment;

  const buttonProps = useMemo(() => {
    if (isAdvancedRoleAndAssignmentPresent) {
      return {
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
      return {
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
      return {
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
      return {
        className: `button small add-available-article ${
          isLoading ? 'disabled' : 'dark'
        }`,
        onClick: () => assignArticle(this.current_user.id),
        text: I18n.t('article_finder.assign_article_self'),
      };
    }
    return { onClick: null };
  }, [isAdvanced, isStudent, isAssignment]);

  const rowButton = () => {
    const { onClick, className, text } = buttonProps;

    return (
      <td>
        {buttonProps ? (
          <button className={className} onClick={onClick}>
            {text}
          </button>
        ) : null}
      </td>
    );
  };

  const _article = useMemo(() => {
    const new_article = {
      ...article,
      language: selectedWiki.language,
      project: selectedWiki.project,
      url: `https://${selectedWiki.language}.${
        selectedWiki.project
      }.org/wiki/${article.title.replace(/ /g, '_')}`,
    };

    if (selectedWiki.project === 'wikidata') {
      delete new_article.language;
      new_article.url = `https://${
        selectedWiki.project
      }.org/wiki/${article.title.replace(/ /g, '_')}`;
    }

    return new_article;
  }, [selectedWiki.project, article]);

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
      {revScore()}
      {grade()}
      <td>{pageviews()}</td>
      {rowButton()}
    </tr>
  );
};

export default ArticleFinderRow;
