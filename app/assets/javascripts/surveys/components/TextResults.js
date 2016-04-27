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
      const sentiment = a.sentiment;
      let sentimentScore = null;
      if (sentiment.label !== undefined) {
        sentimentScore = <div>sentiment:&nbsp;{sentiment.label} ({sentiment.score})</div>;
      }
      return (
        <div key={`answer_${answer.id}`} style={{ padding: 10, borderBottom: '1px solid black' }}>
          <div>{user.username}</div>
          {sentimentScore}
          <div>{answer.answer_text}</div>
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
      <div>
        <strong>Average Sentiment:</strong>&nbsp;
        {sentiment.label} : {sentiment.average}
      </div>
    );
  }

  render() {
    return (
      <div>
        {this.averageSentiment()}
        {this.answersList()}
      </div>
    );
  }
}

TextResults.propTypes = {
  answers_data: PropTypes.array.isRequired,
  sentiment: PropTypes.object
};
