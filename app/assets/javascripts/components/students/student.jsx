import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import ServerActions from '../../actions/server_actions.js';

import AssignCell from './assign_cell.jsx';

import RevisionStore from '../../stores/revision_store.js';
import TrainingStatusStore from '../../stores/training_status_store.js';
import { trunc } from '../../utils/strings';

const Student = createReactClass({
  displayName: 'Student',

  propTypes: {
    student: PropTypes.object.isRequired,
    course: PropTypes.object.isRequired,
    current_user: PropTypes.object,
    editable: PropTypes.bool,
    assigned: PropTypes.array,
    reviewing: PropTypes.array,
    isOpen: PropTypes.bool,
    toggleDrawer: PropTypes.func
  },

  stop(e) {
    return e.stopPropagation();
  },

  openDrawer() {
    RevisionStore.clear();
    TrainingStatusStore.clear();
    ServerActions.fetchRevisions(this.props.student.id, this.props.course.id);
    ServerActions.fetchTrainingStatus(this.props.student.id, this.props.course.id);
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
        (<a onClick={this.stop} href={this.props.student.contribution_url} target="_blank">
          {trunc(this.props.student.username)}
        </a>)
      </span>
    ) : (
      <span><a onClick={this.stop} href={this.props.student.contribution_url} target="_blank">
        {trunc(this.props.student.username)}
      </a></span>
    );

    const trainingProgress = this.props.student.course_training_progress ? (
      <small className="red">{this.props.student.course_training_progress}</small>
    ) : undefined;

    let assignButton;
    let reviewButton;
    if (this.props.course.published) {
      assignButton = (
        <AssignCell
          {...this.props}
          role={0}
          editable={this.props.editable}
          assignments={this.props.assigned}
        />
      );

      reviewButton = (
        <AssignCell
          {...this.props}
          role={1}
          editable={this.props.editable}
          assignments={this.props.reviewing}
        />
      );
    }

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
        <td><button className="icon icon-arrow table-expandable-indicator" /></td>
      </tr>
    );
  }
}
);

export default Student;
