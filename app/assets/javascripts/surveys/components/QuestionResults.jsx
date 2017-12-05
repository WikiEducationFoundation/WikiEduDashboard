import React, { Component } from 'react';
import BarGraph from './BarGraph.jsx';
import TextResults from './TextResults.jsx';
import RangeGraph from './RangeGraph.jsx';
import FollowUpQuestionResults from './FollowUpQuestionResults.jsx';

export default class QuestionResults extends Component {
  _renderQuestionResults(question) {
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
  }

  _data() {
    return null;
  }

  render() {
    return (
      <div>
        {this._renderQuestionResults(this.props)}
        <FollowUpQuestionResults {...this.props} />
        {this._data()}
      </div>
    );
  }
}
