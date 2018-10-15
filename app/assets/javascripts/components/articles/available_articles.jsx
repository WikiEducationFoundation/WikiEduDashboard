import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { Link } from 'react-router';
import shallowCompare from 'react-addons-shallow-compare';

import AssignCell from '../students/assign_cell.jsx';
import ConnectedAvailableArticle from './available_article.jsx';
import AvailableArticlesList from '../articles/available_articles_list.jsx';
import { ASSIGNED_ROLE } from '../../constants';

const AvailableArticles = createReactClass({
  displayName: 'AvailableArticles',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object,
    current_user: PropTypes.object,
    assignments: PropTypes.array
  },

  shouldComponentUpdate(nextProps, nextState) {
    return shallowCompare(this, nextProps, nextState);
  },

  render() {
    let assignCell;
    let availableArticles;
    let elements = [];
    let findingArticlesTraining;
    if (Features.wikiEd && this.props.current_user.isNonstudent) {
      findingArticlesTraining = (
        <a href="/training/instructors/finding-articles" target="_blank" className="button ghost-button small">
          How to find articles
        </a>
      );
    }

    if (this.props.assignments.length > 0) {
      elements = this.props.assignments.map((assignment) => {
        if (assignment.user_id === null) {
          return (
            <ConnectedAvailableArticle
              {...this.props}
              assignment={assignment}
              key={assignment.id}
            />
          );
        }
        return null;
      });
      elements = _.compact(elements);
    }

    if (this.props.course.id) {
      assignCell = (
        <AssignCell
          course={this.props.course}
          role={ASSIGNED_ROLE}
          editable
          addAvailable={true}
          course_id={this.props.course_id}
          current_user={this.props.current_user}
          assignments={[]}
          prefix={I18n.t('users.my_assigned')}
        />
      );
    }

    const showAvailableArticles = elements.length > 0 || this.props.current_user.isNonstudent;

    if (showAvailableArticles) {
      availableArticles = (
        <div id="available-articles" className="mt4">
          <div className="section-header">
            <h3>{I18n.t('articles.available')}</h3>
            <div className="section-header__actions">
              {findingArticlesTraining}
              {assignCell}
              <Link to={`/courses/${this.props.course_id}/article_finder`}><button className="button border small ml2">Find Articles</button></Link>
            </div>
          </div>
          <AvailableArticlesList {...this.props} elements={elements} />
        </div>
      );
    } else {
      availableArticles = null;
    }

    return availableArticles;
  }
});

export default AvailableArticles;
