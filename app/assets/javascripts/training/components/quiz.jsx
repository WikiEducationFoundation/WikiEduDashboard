import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import TrainingActions from '../actions/training_actions.js';
const md = require('../../utils/markdown_it.js').default();

const Quiz = createReactClass({
  displayName: 'Quiz',

  propTypes: {
    selectedAnswerId: PropTypes.number,
    correctAnswer: PropTypes.number,
    selectedAnswer: PropTypes.number,
    answers: PropTypes.array,
    question: PropTypes.string
  },

  getInitialState() {
    return { selectedAnswerId: this.props.selectedAnswerId };
  },

  componentWillReceiveProps(newProps) {
    return this.setState({ selectedAnswerId: newProps.selectedAnswerId });
  },

  setSelectedAnswer(id) {
    return TrainingActions.setSelectedAnswer(id);
  },

  setAnswer(e) {
    return this.setState({ selectedAnswerId: e.currentTarget.getAttribute('data-answer-id') });
  },

  verifyAnswer(e) {
    e.preventDefault();
    e.stopPropagation();
    return this.setSelectedAnswer(this.state.selectedAnswerId);
  },

  correctStatus(answer) {
    if (this.props.correctAnswer === answer) {
      return ' correct';
    }
    return ' incorrect';
  },

  visibilityStatus(answer) {
    if (this.props.selectedAnswer === answer) {
      return ' shown';
    }
    return ' hidden';
  },

  render() {
    const answers = this.props.answers.map((answer, i) => {
      let explanationClass = 'assessment__answer-explanation';
      explanationClass += this.correctStatus(answer.id);
      explanationClass += this.visibilityStatus(answer.id);
      const defaultChecked = parseInt(this.props.selectedAnswer) === answer.id;
      const checked = this.state.selectedAnswerId ? parseInt(this.state.selectedAnswerId) === answer.id : defaultChecked;
      let liClass = this.visibilityStatus(answer.id) === ' shown' ? ' revealed' : undefined;
      liClass += this.correctStatus(answer.id);
      const rawExplanationHtml = md.render(answer.explanation);
      return (
        <li key={i} className={liClass}>
          <label>
            <div>
              <input
                onChange={this.setAnswer}
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
        <h3>{this.props.question}</h3>
        <fieldset>
          <ul>
            {answers}
          </ul>
        </fieldset>
        <button className="btn btn-primary ghost-button capitalize btn-med" onClick={this.verifyAnswer}>Check Answer</button>
      </form>
    );
  }
});

export default Quiz;
