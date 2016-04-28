import React, { Component, PropTypes } from 'react';
import BarGraph from './BarGraph';
import TextResults from './TextResults';
import RangeGraph from './RangeGraph';
import FollowUpQuestionResults from './FollowUpQuestionResults';

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
        return <TextResults { ...question } />;
      default:
        return null;
    }
  }

  _data() {
    return null;
    // return <div><strong>{this.props.type}</strong><pre>{JSON.stringify(this.props, null, '\t')}</pre></div>;
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

QuestionResults.propTypes = {
  type: PropTypes.string.isRequired
};
