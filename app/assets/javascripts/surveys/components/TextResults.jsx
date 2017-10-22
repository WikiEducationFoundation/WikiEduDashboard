import _ from 'lodash';
import PropTypes from 'prop-types';
import React, { Component } from 'react';
const INITIAL_LIMIT = 3;

export default class TextResults extends Component {
  constructor(props) {
    super();
    const { followUpOnly, answers_data } = props;
    this.followUpAnswers = _.filter(props.follow_up_answers, (a) => {
      return !_.isEmpty(a);
    });
    this.showButton = answers_data.length > INITIAL_LIMIT;
    let limit = answers_data.length < INITIAL_LIMIT ? answers_data.length : INITIAL_LIMIT;
    if (followUpOnly) {
      limit = this.followUpAnswers.length < INITIAL_LIMIT ? this.followUpAnswers.length : INITIAL_LIMIT;
      this.showButton = this.followUpAnswers.length > INITIAL_LIMIT;
    }
    this.state = {
      sentiment: null,
      limit,
      buttonText: 'More'
    };
    this.toggleShowMore = this._toggleShowMore.bind(this);
  }
  answersList() {
    const { followUpOnly } = this.props;
    const _answers = this.props.answers_data;
    const answers = _answers.slice(0, this.state.limit);
    const followUpAnswers = this.followUpAnswers;
    const list = answers.map((a, i) => {
      const { course } = a;
      const courseTitle = course === null ? null : course.title;
      const answer = a.data;
      const user = a.user;
      const sentiment = a.sentiment;
      let sentimentScore = null;
      if (sentiment.label !== undefined) {
        sentimentScore = <div className={`results__text__sentiment results__text__sentiment--${sentiment.label}`}>{sentiment.label} ({sentiment.score})</div>;
      }
      const noFollowUpAnswer = followUpAnswers[i] === undefined || followUpAnswers[i] === '';
      const followUpAnswer = noFollowUpAnswer ? null : <em className="results__text__follow-up-answer">{followUpAnswers[i]}</em>;
      const answerText = <div className="results__text__answer">{answer.answer_text}</div>;
      if (followUpOnly && noFollowUpAnswer) {
        return null;
      }
      return (
        <div key={`answer_${answer.id}`} className="results__text-answer">
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
    return list;
  }

  averageSentiment() {
    const { sentiment } = this.props;
    if (sentiment === null) {
      return null;
    }
    return (
      <div className={`results__text__sentiment--average results__text__sentiment--${sentiment.label}`}>
        <strong>Average Sentiment</strong>:&nbsp;{sentiment.label} : {sentiment.average}
      </div>
    );
  }

  _toggleShowMore() {
    const { followUpOnly } = this.props;
    const { limit } = this.state;
    const totalAnswers = this.props.answers_data.length;
    const followUpAnswers = this.followUpAnswers;
    const total = followUpOnly ? followUpAnswers.length : totalAnswers;
    const min = followUpAnswers < 3 ? followUpAnswers.length : 3;
    const buttonText = limit < total ? 'Less' : 'More';
    this.setState({ limit: limit < total ? total : min, buttonText });
  }

  _showMore() {
    const { followUpOnly } = this.props;
    const { limit, buttonText } = this.state;
    const answers = this.props.answers_data;
    const followUpAnswers = this.followUpAnswers;
    if (followUpOnly && followUpAnswers.length < limit ||
        !followUpOnly && answers.length < limit) {
      return null;
    }
    const button = this.showButton ? <button type="button" className="link-button" onClick={this.toggleShowMore}>{`Show ${buttonText}`}</button> : null;
    return (
      <div className="results__text-answer__info">
        <span className="contextual">
          Displaying {limit} of
          &nbsp;{(followUpOnly ? followUpAnswers.length : answers.length)}
          &nbsp;{(followUpOnly ? 'follow-up answers' : 'answers')}.
        </span>
        {button}
      </div>
    );
  }

  render() {
    const followUpQuestionText = this.props.question.follow_up_question_text;
    const followUpQuestion = followUpQuestionText === '' ? null : <em className="results__text__follow-up-question">{followUpQuestionText}</em>;
    return (
      <div>
        <div className="results__text">
          {followUpQuestion}
          {this.averageSentiment()}
          {this.answersList()}
        </div>
        {this._showMore()}
      </div>
    );
  }
}

TextResults.propTypes = {
  answers_data: PropTypes.array.isRequired,
  sentiment: PropTypes.object,
  question: PropTypes.object,
  follow_up_answers: PropTypes.array,
  followUpOnly: PropTypes.bool
};
