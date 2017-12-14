import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';

import AssignCell from '../students/assign_cell.jsx';
import ConnectedAvailableArticle from './available_article.jsx';
import AvailableArticlesList from '../articles/available_articles_list.jsx';
import AssignmentStore from '../../stores/assignment_store.js';

function getState() {
  return {
    assignments: AssignmentStore.getModels()
  };
}

const AvailableArticles = createReactClass({
  displayName: 'AvailableArticles',

  propTypes: {
    course_id: PropTypes.string,
    course: PropTypes.object,
    current_user: PropTypes.object
  },

  mixins: [AssignmentStore.mixin],

  getInitialState() {
    return getState();
  },

  storeDidChange() {
    this.setState(getState());
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

    if (this.state.assignments.length > 0) {
      elements = this.state.assignments.map((assignment) => {
        if (assignment.user_id === null && !assignment.deleted) {
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
          role={0}
          editable
          add_available={true}
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
