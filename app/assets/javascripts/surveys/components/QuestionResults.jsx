import React from 'react';
import BarGraph from './BarGraph.jsx';
import TextResults from './TextResults.jsx';
import RangeGraph from './RangeGraph.jsx';
import FollowUpQuestionResults from './FollowUpQuestionResults.jsx';

const QuestionResults = (props) => {
  const _renderQuestionResults = (question) => {
    const { type } = question;
    switch (type) {
      case 'radio':
      case 'checkbox':
      case 'select':
        return <BarGraph {...question} />;
      case 'rangeinput':
        return <RangeGraph {...question} />;
      case 'text':
      case 'long':
        return <TextResults {...question} />;
      default:
        return null;
    }
  };

  return (
    <div>
      {_renderQuestionResults(props)}
      <FollowUpQuestionResults {...props} />
    </div>
  );
};

export default (QuestionResults);
