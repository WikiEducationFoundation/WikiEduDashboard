import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';

const INITIAL_LIMIT = 3;

const TextResults = ({ followUpOnly, answers_data, follow_up_answers: followUpAnswers, sentiment, question }) => {
  const [limit, setLimit] = useState();
  const [buttonText, setbuttonText] = useState('More');

  const followUpAnswerCount = Object.keys(followUpAnswers).length;
  const showButton = followUpOnly
    ? followUpAnswerCount > INITIAL_LIMIT
    : answers_data.length > INITIAL_LIMIT;

  useEffect(() => {
    let chosenLimit = answers_data.length < INITIAL_LIMIT ? answers_data.length : INITIAL_LIMIT;
    if (followUpOnly) {
      chosenLimit = followUpAnswerCount < INITIAL_LIMIT ? followUpAnswerCount : INITIAL_LIMIT;
    }
    setLimit(chosenLimit);
  }, [answers_data, followUpOnly, followUpAnswers]);

  const answersList = () => {
    const answers = answers_data;
    const list = answers.map((answer) => {
      const { course, data: answerData, user, sentiment: answerSentiment } = answer;
      const courseTitle = course === null ? null : course.title;

      let sentimentScore = null;
      if (answerSentiment.label !== undefined) {
        sentimentScore = <div className={`results__text__sentiment results__text__sentiment--${answerSentiment.label}`}>{answerSentiment.label} ({answerSentiment.score})</div>;
      }
      const noFollowUpAnswer = followUpAnswers[answerData.id] === undefined || followUpAnswers[answerData.id] === '';
      const followUpAnswer = noFollowUpAnswer ? null : <em className="results__text__follow-up-answer">{followUpAnswers[answerData.id]}</em>;
      const answerText = <div className="results__text__answer">{answerData.answer_text}</div>;
      if (followUpOnly && noFollowUpAnswer) {
        return null;
      }
      return (
        <div key={`answer_${answerData.id}`} className="results__text-answer">
          <div className="results__text-answer__info">
            <strong>{user.username}</strong>
            <span className="results__text-answer__course-title">{courseTitle}</span>
          </div>
          {sentimentScore}
          {(followUpOnly === undefined ? answerText : null)}
          {followUpAnswer}
        </div>
      );
    });
    return list.filter(e => e).slice(0, limit);
  };

  const averageSentiment = () => {
    if (sentiment === null) {
      return null;
    }
    return (
      <div className={`results__text__sentiment--average results__text__sentiment--${sentiment.label}`}>
        <strong>Average Sentiment</strong>:&nbsp;{sentiment.label} : {sentiment.average}
      </div>
    );
  };

  const toggleShowMore = () => {
    const totalAnswers = answers_data.length;
    const total = followUpOnly ? followUpAnswerCount : totalAnswers;
    const min = followUpAnswers < 3 ? followUpAnswers.length : 3;
    setbuttonText(limit < total ? 'Less' : 'More');
    setLimit(limit < total ? total : min);
  };

  const showMore = () => {
    const answers = answers_data;
    if ((followUpOnly && followUpAnswers.length < limit)
      || (!followUpOnly && answers.length < limit)) {
      return null;
    }
    const button = showButton ? <button type="button" className="link-button" onClick={toggleShowMore}>{`Show ${buttonText}`}</button> : null;
    return (
      <div className="results__text-answer__info">
        <span className="contextual">
          Displaying {limit} of
          &nbsp;{(followUpOnly ? followUpAnswerCount : answers.length)}
          &nbsp;{(followUpOnly ? 'follow-up answers' : 'answers')}.
        </span>
        {button}
      </div>
    );
  };

  const followUpQuestionText = question.follow_up_question_text;
  const followUpQuestion = followUpQuestionText === '' ? null : <em className="results__text__follow-up-question">{followUpQuestionText}</em>;
  return (
    <div>
      <div className="results__text">
        {followUpQuestion}
        {averageSentiment()}
        {answersList()}
      </div>
      {showMore()}
    </div>
  );
};

TextResults.propTypes = {
  answers_data: PropTypes.array.isRequired,
  sentiment: PropTypes.object,
  question: PropTypes.object,
  followUpAnswers: PropTypes.object,
  followUpOnly: PropTypes.bool
};

export default (TextResults);
