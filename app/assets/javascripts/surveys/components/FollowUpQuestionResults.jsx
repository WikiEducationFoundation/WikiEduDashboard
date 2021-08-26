import React, { Component } from 'react';
import PropTypes from 'prop-types';
import TextResults from './TextResults.jsx';

export default class FollowUpQuestionResults extends Component {
  render() {
    const answerCount = Object.keys(this.props.follow_up_answers).length;
    if (answerCount === 0) {
      return null;
    }
    return (
      <div>
        <h4>Follow Up Question</h4>
        <TextResults {...this.props} followUpOnly={true} />
      </div>
    );
  }
}

FollowUpQuestionResults.propTypes = {
  follow_up_answers: PropTypes.object,
  type: PropTypes.string
};
