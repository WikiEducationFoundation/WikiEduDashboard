import React from 'react';
import createReactClass from 'create-react-class';
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

const AvailableArticles = createReactClass({
  displayName: 'AvailableArticles',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object,
    current_user: PropTypes.object,
    assignments: PropTypes.array
  },

  componentDidMount() {
    // sets the title of this tab
    const project = this.props.course.home_wiki.project;
    document.title = `${this.props.course.title} - ${ArticleUtils.I18n('available', project)}`;
  },

  render() {
    let assignCell;
    let availableArticles;
    let elements = [];
    let findingArticlesTraining;
    const { assignments, course, course_id, current_user } = this.props;

    const { assigned } = processAssignments(this.props);

    const project = course.home_wiki.project;
    const articlesOrItems = ArticleUtils.articlesOrItems(project);

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
          How to find {articlesOrItems}
        </a>
      );
    }

    if (assignments.length > 0) {
      const assignedUrls = assigned.map(assignment => assignment.article_url);
      elements = assignments.map((assignment) => {
        if (assignment.user_id === null) {
          return (
            <ConnectedAvailableArticle
              {...this.props}
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
              <Link to={`/courses/${course_id}/article_finder`}><button className="button border small ml2">Find {articlesOrItems}</button></Link>
            </div>
          </div>
          <AvailableArticlesList {...this.props} elements={elements} />
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
  }
});

export default AvailableArticles;
