import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { reviewAnswer } from '../../actions/training_actions.js';

const md = require('../../utils/markdown_it.js').default();

const Quiz = (props) => {
  const [selectedAnswerId, setSelectedAnswerId] = useState(null);

 const setAnswer = (e) => {
    return setSelectedAnswerId(e.currentTarget.getAttribute('data-answer-id'));
  };

  const reviewAnswers = (id) => {
    return props.reviewAnswer(id);
  };

  const verifyAnswer = (e) => {
    e.preventDefault();
    e.stopPropagation();
    return reviewAnswers(selectedAnswerId);
  };

  const correctStatus = (answer) => {
    if (props.correctAnswer === answer) {
      return ' correct';
    }
    return ' incorrect';
  };

  const visibilityStatus = (answer) => {
    if (props.selectedAnswer === answer) {
      return ' shown';
    }
    return ' hidden';
  };

    const answers = props.answers.map((answer, i) => {
      let explanationClass = 'assessment__answer-explanation';
      explanationClass += correctStatus(answer.id);
      explanationClass += visibilityStatus(answer.id);
      const defaultChecked = parseInt(props.selectedAnswer) === answer.id;
      const checked = selectedAnswerId ? parseInt(selectedAnswerId) === answer.id : defaultChecked;
      let liClass = visibilityStatus(answer.id) === ' shown' ? ' revealed' : undefined;
      liClass += correctStatus(answer.id);
      const rawExplanationHtml = md.render(answer.explanation);
      return (
        <li key={i} className={liClass}>
          <label>
            <div>
              <input
                onChange={setAnswer}
                data-answer-id={answer.id}
                checked={checked}
                type="radio"
                name="answer"
              />
            </div>
            {answer.text}
          </label>
          <div className={explanationClass} dangerouslySetInnerHTML={{ __html: rawExplanationHtml }} />
        </li>
      );
    });

    return (
      <form className="training__slide__quiz">
        <h3>{props.question}</h3>
        <fieldset>
          <ul>
            {answers}
          </ul>
        </fieldset>
        <button className="btn btn-primary ghost-button capitalize btn-med" onClick={verifyAnswer}> {I18n.t('training.check_answer')} </button>
      </form>
    );
  };
Quiz.displayName = 'Quiz';

Quiz.propTypes = {
    selectedAnswerId: PropTypes.number,
    correctAnswer: PropTypes.number,
    selectedAnswer: PropTypes.number,
    answers: PropTypes.array,
    question: PropTypes.string
  };

const mapDispatchToProps = {
  reviewAnswer
};

export default connect(null, mapDispatchToProps)(Quiz);
