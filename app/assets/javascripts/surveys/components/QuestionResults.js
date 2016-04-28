import React, { Component, PropTypes } from 'react';
import BarGraph from './BarGraph';
import TextResults from './TextResults';
import RangeGraph from './RangeGraph';
import FollowUpQuestionResults from './FollowUpQuestionResults';
import CopyToClipboard from 'react-copy-to-clipboard';

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
    if (process.env.NODE_ENV === 'production') {
      return null;
    }
    return <CopyToClipboard style={{ fontSize: 14 }} text={JSON.stringify(this.props, null, '\t')} onCopy={ () => {alert('copied to your clipboard!');}}><span style={{ cursor: 'pointer' }}>Copy JSON</span></CopyToClipboard>;
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
