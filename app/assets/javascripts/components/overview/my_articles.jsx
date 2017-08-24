import React from 'react';
import AssignCell from '../students/assign_cell.jsx';
import AssignmentStore from '../../stores/assignment_store.js';
import ServerActions from '../../actions/server_actions.js';
import MyAssignment from './my_assignment.jsx';

const MyArticles = React.createClass({
  displayName: 'MyArticles',

  propTypes: {
    course: React.PropTypes.object,
    current_user: React.PropTypes.object,
    course_id: React.PropTypes.string
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

    return (
      <div className="module my-articles">
        <div className="section-header my-articles-header">
          <h3>{I18n.t('courses.my_articles')}</h3>
          <div className="controls">
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
