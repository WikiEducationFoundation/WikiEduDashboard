import React from 'react';
import PropTypes from 'prop-types';
import TextResults from './TextResults.jsx';

const FollowUpQuestionResults = (props) => {
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
