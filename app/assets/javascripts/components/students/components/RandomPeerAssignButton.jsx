import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import createReactClass from 'create-react-class';

import { initiateConfirm } from '../../../actions/confirm_actions';
import { randomPeerAssignments } from '../../../actions/assignment_actions';

const RandomPeerAssignButton = createReactClass({
  displayName: 'RandomPeerAssignButton',

  propTypes: {
    addAssignments: PropTypes.func,
    course: PropTypes.object,
    current_user: PropTypes.object,
    initiateConfirm: PropTypes.func,
    role: PropTypes.number
  },

  randomPeerAssign() {
    const onConfirm = () => {
      this.props.randomPeerAssignments({
        course_slug: this.props.course.slug,
        role: this.props.role,
        random: true
      });
    };

    // Confirm for assigning an article to a student
    const confirmMessage = I18n.t('assignments.random_peer_review.confirm_addition');
    this.props.initiateConfirm({ confirmMessage, onConfirm });
  },

  render() {
    if (!this.props.current_user.isInstructor) {
      return <div/>;
    }

    return (
      <div className="tooltip-trigger">
        <button className="button border small assign-button" onClick={this.randomPeerAssign}>
          {I18n.t('assignments.random_peer_review.heading')} {<span className="tooltip-indicator" />}
        </button>
        <div className="tooltip">
          <p>
            {I18n.t('assignments.random_peer_review.tooltip_message')}
          </p>
        </div>
      </div>
    );
  }
}
);

const mapDispatchToProps = {
  randomPeerAssignments,
  initiateConfirm
};

export default connect(null, mapDispatchToProps)(RandomPeerAssignButton);
