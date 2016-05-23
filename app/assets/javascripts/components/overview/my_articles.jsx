import React from 'react';
import AssignCell from '../students/assign_cell.cjsx';
import AssignmentStore from '../../stores/assignment_store.coffee';
import ServerActions from '../../actions/server_actions.js';

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

    return (
      <div className="module">
        <div className="section-header">
          <h3>{I18n.t('courses.my_articles')}</h3>
        </div>
        <div className="module__data">
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
          />
          <br />
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
          />
        </div>
      </div>
    );
  }
});

export default MyArticles;
