import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import AssignCell from '../students/assign_cell.jsx';
import AssignmentStore from '../../stores/assignment_store.js';
import ServerActions from '../../actions/server_actions.js';
import MyAssignment from './my_assignment.jsx';

const MyArticles = createReactClass({
  displayName: 'MyArticles',

  propTypes: {
    course: PropTypes.object,
    current_user: PropTypes.object,
    course_id: PropTypes.string
  },

  componentDidMount() {
    ServerActions.fetch('assignments', this.props.course_id);
  },

  render() {
    const assignOptions = { user_id: this.props.current_user.id, role: 0 };
    const reviewOptions = { user_id: this.props.current_user.id, role: 1 };

    const assigned = AssignmentStore.getFiltered(assignOptions);
    const reviewing = AssignmentStore.getFiltered(reviewOptions);
    const allAssignments = assigned.concat(reviewing);
    const assignmentCount = allAssignments.length;
    const assignments = allAssignments.map((assignment, i) => {
      return (
        <MyAssignment
          key={assignment.id}
          assignment={assignment}
          course={this.props.course}
          username={this.props.current_user.username}
          last={i === assignmentCount - 1}
          current_user={this.props.current_user}
        />
      );
    });

    let findYourArticleTraining;
    if (Features.wikiEd && !assignmentCount) {
      findYourArticleTraining = (
        <a href="/training/students/finding-your-article" target="_blank" className="button ghost-button small">
          How to find an article
        </a>
      );
    }

    return (
      <div className="module my-articles">
        <div className="section-header my-articles-header">
          <h3>{I18n.t('courses.my_articles')}</h3>
          <div className="controls">
            {findYourArticleTraining}
            <AssignCell
              id="user_assigned"
              course={this.props.course}
              role={0}
              editable
              course_id={this.props.course_id}
              current_user={this.props.current_user}
              student={this.props.current_user}
              assignments={assigned}
              prefix={I18n.t('users.my_assigned')}
              tooltip_message={I18n.t('assignments.assign_tooltip')}
            />
            <AssignCell
              id="user_reviewing"
              course={this.props.course}
              role={1}
              editable
              course_id={this.props.course_id}
              current_user={this.props.current_user}
              student={this.props.current_user}
              assignments={reviewing}
              prefix={I18n.t('users.my_reviewing')}
              tooltip_message={I18n.t('assignments.review_tooltip')}
            />
          </div>
        </div>
        {assignments}
      </div>
    );
  }
});

export default MyArticles;
