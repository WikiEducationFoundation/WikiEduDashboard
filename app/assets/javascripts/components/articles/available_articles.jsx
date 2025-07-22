import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { compact } from 'lodash-es';
import { Link } from 'react-router-dom';

import AssignCell from '@components/common/AssignCell/AssignCell.jsx';
import ConnectedAvailableArticle from './available_article.jsx';
import AvailableArticlesList from '../articles/available_articles_list.jsx';
import MyArticlesContainer from '../overview/my_articles/containers';
import { ASSIGNED_ROLE } from '../../constants';
import { processAssignments } from '../overview/my_articles/utils/processAssignments';
import ArticleUtils from '../../utils/article_utils.js';

const AvailableArticles = (props) => {
  useEffect(() => {
    const project = props.course.home_wiki.project;
    document.title = `${props.course.title} - ${ArticleUtils.I18n('available', project)}`;
  }, []);

  let assignCell;
  let availableArticles;
  let elements = [];
  let findingArticlesTraining;
  const { assignments, course, course_id, current_user } = props;

  const { assigned } = processAssignments(props);

  const project = course.home_wiki.project;
  const isWikidataCourse = course.home_wiki && course.home_wiki.project === 'wikidata';
  const showMyArticlesSection = assigned.length && current_user.isStudent && !isWikidataCourse;
  let myArticles;
  if (showMyArticlesSection) {
    myArticles = (
      <MyArticlesContainer current_user={current_user} />
    );
  }

  if (Features.wikiEd && current_user.isAdvancedRole) {
    findingArticlesTraining = (
      <a href="/training/instructors/finding-articles" target="_blank" className="button ghost-button small">
        {ArticleUtils.I18n('how_to_find', project)}
      </a>
    );
  }

  if (assignments.length > 0) {
    const assignedUrls = assigned.map(assignment => assignment.article_url);
    elements = assignments.map((assignment) => {
      if (assignment.user_id === null) {
        return (
          <ConnectedAvailableArticle
            {...props}
            selectable={!assignedUrls.includes(assignment.article_url)}
            assignment={assignment}
            key={assignment.id}
          />
        );
      }
      return null;
    });
    elements = compact(elements);
  }

  if (course.id) {
    assignCell = (
      <AssignCell
        course={course}
        role={ASSIGNED_ROLE}
        editable
        allowMultipleArticles={true}
        course_id={course_id}
        current_user={current_user}
        assignments={[]}
        prefix={I18n.t('users.my_assigned')}
      />
    );
  }

  const showAvailableArticles = elements.length > 0 || current_user.isAdvancedRole;
  if (showAvailableArticles) {
    availableArticles = (
      <div id="available-articles" className="mt4">
        <div className="section-header">
          <h3>{ ArticleUtils.I18n('available', project)}</h3>
          <div className="section-header__actions">
            {findingArticlesTraining}
            {assignCell}
            <Link to={`/courses/${course_id}/article_finder`}><button className="button border small ml2">{ArticleUtils.I18n('find', project)}</button></Link>
          </div>
        </div>
        <AvailableArticlesList {...props} elements={elements} />
      </div>
    );
  } else {
    availableArticles = null;
  }

  return (
    <>
      {myArticles}
      {availableArticles}
    </>
  );
};

AvailableArticles.propTypes = {
  course_id: PropTypes.string,
  course: PropTypes.object,
  current_user: PropTypes.object,
  assignments: PropTypes.array,
};

export default AvailableArticles;
