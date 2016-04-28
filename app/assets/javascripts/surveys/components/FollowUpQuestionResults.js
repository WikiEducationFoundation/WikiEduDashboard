import _ from 'lodash';
import React, { Component, PropTypes } from 'react';
import TextResults from './TextResults';

export default class FollowUpQuestionResults extends Component {
  render() {
    const { type } = this.props;
    const answers = _.filter(this.props.follow_up_answers, (a) => {
      return !_.isEmpty(a);
    });
    if (answers === undefined || answers.length === 0) {
      return null;
    }
    if (type === 'text' || type === 'long') {
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
  follow_up_answers: PropTypes.array,
  question: PropTypes.object,
  type: PropTypes.string
};
