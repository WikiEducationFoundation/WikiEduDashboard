import React from 'react';
import createReactClass from 'create-react-class';
import { Link } from 'react-router-dom';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { setUploadFilters } from '../../actions/uploads_actions';
import { fetchUserRevisions } from '../../actions/user_revisions_actions';
import { fetchTrainingStatus } from '../../actions/training_status_actions';
import { getFiltered } from '../../utils/model_utils.js';
import { ASSIGNED_ROLE } from '../../constants/assignments';

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
    fetchTrainingStatus: PropTypes.func.isRequired,
    wikidataLabels: PropTypes.object
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
        <a href={`/users/${this.props.student.username}`}>
          {trunc(this.props.student.username)}
        </a>)
      </span>
      )
      : (
        <span>
          <a href={`/users/${this.props.student.username}`}>
            {trunc(this.props.student.username)}
          </a>
        </span>
    );

    const trainingProgress = this.props.student.course_training_progress ? (
      <small className="red">{this.props.student.course_training_progress}</small>
    ) : undefined;

    let recentRevisions;
    if (this.props.showRecent) {
      recentRevisions = <td className="desktop-only-tc">{this.props.student.recent_revisions}</td>;
    }

    let assignButton;
    let reviewButton;
    if (this.props.course.published) {
      const assignOptions = { user_id: this.props.student.id, role: ASSIGNED_ROLE };
      const assigned = getFiltered(this.props.assignments, assignOptions);

      const unassignedOptions = { user_id: null, role: ASSIGNED_ROLE };
      const unassigned = getFiltered(this.props.assignments, unassignedOptions);
      assignButton = (
        <AssignCell
          assignments={assigned}
          course={this.props.course}
          current_user={this.props.current_user}
          editable={this.props.editable}
          student={this.props.student}
          role={0}
          wikidataLabels={this.props.wikidataLabels}
          unassigned={unassigned}
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
          wikidataLabels={this.props.wikidataLabels}
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
          <div className="sandbox-link">
            <a onClick={this.stop} href={this.props.student.sandbox_url} target="_blank">{I18n.t('users.sandboxes')}</a>
            &nbsp;
            <a onClick={this.stop} href={this.props.student.contribution_url} target="_blank">{I18n.t('users.edits')}</a>
          </div>
        </td>
        <td className="desktop-only-tc">
          {assignButton}
        </td>
        <td className="desktop-only-tc">
          {reviewButton}
        </td>
        {recentRevisions}
        <td className="desktop-only-tc">
          {this.props.student.character_sum_ms} | {this.props.student.character_sum_us} | {this.props.student.character_sum_draft}
        </td>
        <td className="desktop-only-tc">
          {this.props.student.references_count}
        </td>
        <td className="desktop-only-tc">
          <Link to={uploadsLink} onClick={() => { this.setUploadFilters([{ value: this.props.student.username, label: this.props.student.username }]); }}>{this.props.student.total_uploads}</Link>
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
