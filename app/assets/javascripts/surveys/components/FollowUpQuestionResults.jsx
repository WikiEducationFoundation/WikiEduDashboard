import _ from 'lodash';
import React, { Component } from 'react';
import PropTypes from 'prop-types';
import TextResults from './TextResults.jsx';

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
  type: PropTypes.string
};
