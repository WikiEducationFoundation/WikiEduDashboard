import React from 'react';
import AssignCell from '../students/assign_cell.jsx';
import AvailableArticle from './available_article.jsx';
import AvailableArticlesList from '../articles/available_article_list.jsx';
import AssignmentStore from '../../stores/assignment_store.js';
import UserStore from '../../stores/user_store.js';
import UserUtils from '../../utils/user_utils.js';

function getState() {
  return {
    assignments: AssignmentStore.getModels()
  };
}

const AvailableArticles = React.createClass({
  displayName: 'AvailableArticles',

  propTypes: {
    course_id: React.PropTypes.string,
    course: React.PropTypes.object,
    current_user: React.PropTypes.object
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

    if (this.state.assignments.length > 0) {
      elements = this.state.assignments.map((assignment) => {
        if (assignment.user_id === null && !assignment.deleted) {
          return (
            <AvailableArticle {...this.props}
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

    const userRoles = UserUtils.userRoles(this.props.current_user, UserStore);
    const showAvailableArticles = elements.length > 0 || userRoles.isNonstudent;

    if (showAvailableArticles) {
      availableArticles = (
        <div id="available-articles" className="mt4">
          <div className="section-header">
            <h3>{I18n.t('articles.available')}</h3>
            <div className="section-header__actions">
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
