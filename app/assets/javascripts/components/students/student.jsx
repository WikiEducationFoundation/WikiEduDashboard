import React from 'react';
import createReactClass from 'create-react-class';
import { Link } from 'react-router';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { setUploadFilters } from '../../actions/uploads_actions';
import { fetchUserRevisions } from '../../actions/user_revisions_actions';
import { fetchTrainingStatus } from '../../actions/training_status_actions';
import { getFiltered } from '../../utils/model_utils.js';

import AssignCell from './assign_cell.jsx';
import { trunc } from '../../utils/strings';

const Student = createReactClass({
  displayName: 'Student',

  propTypes: {
    student: PropTypes.object.isRequired,
    course: PropTypes.object.isRequired,
    current_user: PropTypes.object,
    editable: PropTypes.bool,
    assignments: PropTypes.array,
    isOpen: PropTypes.bool,
    toggleDrawer: PropTypes.func,
    fetchUserRevisions: PropTypes.func.isRequired,
    fetchTrainingStatus: PropTypes.func.isRequired
  },

  setUploadFilters(selectedFilters) {
    this.props.setUploadFilters(selectedFilters);
  },

  stop(e) {
    return e.stopPropagation();
  },

  openDrawer() {
    if (!this.props.isOpen) {
      this.props.fetchUserRevisions(this.props.course.id, this.props.student.id);
      this.props.fetchTrainingStatus(this.props.student.id, this.props.course.id);
    }
    return this.props.toggleDrawer(`drawer_${this.props.student.id}`);
  },

  buttonClick(e) {
    e.stopPropagation();
    return this.openDrawer();
  },

  _shouldShowRealName() {
    const studentRole = 0;
    if (!this.props.student.real_name) { return false; }
    return this.props.current_user && (this.props.current_user.admin || this.props.current_user.role > studentRole);
  },

  render() {
    let className = 'students';
    className += this.props.isOpen ? ' open' : '';

    const userName = this._shouldShowRealName() ? (
      <span>
        <strong>{trunc(this.props.student.real_name)}</strong>
        &nbsp;
        (
        <a onClick={this.stop} href={this.props.student.contribution_url} target="_blank">
          {trunc(this.props.student.username)}
        </a>)
      </span>
      )
      :
      (
        <span>
          <a onClick={this.stop} href={this.props.student.contribution_url} target="_blank">
            {trunc(this.props.student.username)}
          </a>
        </span>
    );

    const trainingProgress = this.props.student.course_training_progress ? (
      <small className="red">{this.props.student.course_training_progress}</small>
    ) : undefined;

    let assignButton;
    let reviewButton;
    if (this.props.course.published) {
      const assignOptions = { user_id: this.props.student.id, role: 0 };
      const assigned = getFiltered(this.props.assignments, assignOptions);
      assignButton = (
        <AssignCell
          course={this.props.course}
          current_user={this.props.current_user}
          student={this.props.student}
          role={0}
          editable={this.props.editable}
          assignments={assigned}
        />
      );

      const reviewOptions = { user_id: this.props.student.id, role: 1 };
      const reviewing = getFiltered(this.props.assignments, reviewOptions);
      reviewButton = (
        <AssignCell
          course={this.props.course}
          current_user={this.props.current_user}
          student={this.props.student}
          role={1}
          editable={this.props.editable}
          assignments={reviewing}
        />
      );
    }

    const uploadsLink = `/courses/${this.props.course.slug}/uploads`;

    return (
      <tr onClick={this.openDrawer} className={className}>
        <td>
          <div className="name">
            {userName}
          </div>
          {trainingProgress}
          <div className="sandbox-link"><a onClick={this.stop} href={this.props.student.sandbox_url} target="_blank">(sandboxes)</a></div>
        </td>
        <td className="desktop-only-tc">
          {assignButton}
        </td>
        <td className="desktop-only-tc">
          {reviewButton}
        </td>
        <td className="desktop-only-tc">{this.props.student.recent_revisions}</td>
        <td className="desktop-only-tc">
          {this.props.student.character_sum_ms} | {this.props.student.character_sum_us} | {this.props.student.character_sum_draft}
        </td>
        <td className="desktop-only-tc">
          <Link to={uploadsLink} onClick={() => { this.setUploadFilters(this.props.student.username); }}>{this.props.student.total_uploads}</Link>
        </td>
        <td><button className="icon icon-arrow table-expandable-indicator" /></td>
      </tr>
    );
  }
}
);

const mapDispatchToProps = {
  setUploadFilters,
  fetchUserRevisions,
  fetchTrainingStatus
};

export default connect(null, mapDispatchToProps)(Student);
