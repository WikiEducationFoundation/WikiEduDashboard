import React, { Component, PropTypes } from 'react';
import { answerTotals } from './utils';

export default class BarGraph extends Component {
  render() {
    const answers = answerTotals(this.props);
    const totalAnswers = this.props.answers.length;
    return (
      <div>
        {Object.keys(answers).map((key) => {
          const total = answers[key];
          const width = ((total / totalAnswers) * 100).toFixed(2);
          const widthPercent = isNaN(width) ? '0%' : `${width}%`;
          return (<div key={key}>
            <strong>{key}</strong>
            <div style={{ height: 20, width: widthPercent, background: '#E5AB28' }}>{ `${widthPercent} (${total})` }</div>
          </div>);
        })}
      </div>
    );
  }
}

BarGraph.propTypes = {
  answers: PropTypes.array.isRequired
};
