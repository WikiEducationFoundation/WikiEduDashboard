import React, { Component, PropTypes } from 'react';

export default class TextResults extends Component {
  constructor() {
    super();
    this.state = {
      sentiment: null
    };
  }
  answersList() {
    const answers = this.props.answers_data;
    const list = answers.map(a => {
      const answer = a.data;
      const user = a.user;
      return (
        <div key={`answer_${answer.id}`} style={{ padding: 10, borderBottom: '1px solid black' }}>
          <div>{user.username}</div>
          <div>sentiment:&nbsp;{a.sentiment.label} : {a.sentiment.score}</div>
          <div>{answer.answer_text}</div>
        </div>
      );
    });
    return list;
  }

  render() {
    return (
      <div>
        <strong>Average Sentiment:</strong>&nbsp;{this.props.sentiment.label} : {this.props.sentiment.average}
        {this.answersList()}
      </div>
    );
  }
}

TextResults.propTypes = {
  answers_data: PropTypes.array.isRequired,
  sentiment: PropTypes.object.isRequired
};
