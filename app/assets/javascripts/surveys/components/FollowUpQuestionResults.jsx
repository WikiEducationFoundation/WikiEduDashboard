import React from 'react';
import PropTypes from 'prop-types';
import TextResults from './TextResults.jsx';

const FollowUpQuestionResults = (props) => {
  const answerCount = Object.keys(props.follow_up_answers).length;
  if (answerCount === 0) {
    return null;
  }
  return (
    <div>
      <h4>Follow Up Question</h4>
      <TextResults {...props} followUpOnly={true} />
    </div>
  );
};

FollowUpQuestionResults.propTypes = {
  follow_up_answers: PropTypes.object,
  type: PropTypes.string
};

export default (FollowUpQuestionResults);
