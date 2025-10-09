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
        return <BarGraph answer_options={question.answer_options} answers={question.answers} />;
      case 'rangeinput':
        return <RangeGraph question={question.question} answers={question.answers} />;
      case 'text':
      case 'long':
        return (
          <TextResults
            answers_data={question.answers_data}
            follow_up_answers={question.follow_up_answers}
            sentiment={question.sentiment}
            question={question.question}
          />
        );
      default:
        return null;
    }
  };

  return (
    <div>
      {_renderQuestionResults(props)}
      { Object.keys(props.follow_up_answers).length && <FollowUpQuestionResults {...props} /> }
    </div>
  );
};

export default (QuestionResults);
