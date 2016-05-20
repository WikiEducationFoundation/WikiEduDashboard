import React from 'react';
import AssignCell from '../students/assign_cell.cjsx';


const MyArticles = React.createClass({
  displayName: 'MyArticles',

  propTypes: {
    course: React.PropTypes.object,
    current_user: React.PropTypes.object,
    course_id: React.PropTypes.string,
    assigned: React.PropTypes.array,
    reviewing: React.PropTypes.array
  },

  render() {
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
            assignments={this.props.assigned}
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
            assignments={this.props.reviewing}
          />
        </div>
      </div>
    );
  }
});

export default MyArticles;
