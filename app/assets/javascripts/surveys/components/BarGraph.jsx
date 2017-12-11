import _ from 'lodash';
import React from 'react';
import PropTypes from 'prop-types';
import { answerTotals } from './utils';

const BarGraph = (props) => {
  const answers = answerTotals(props);
  const totalAnswers = props.answers.length;

  return (
    <div className="results__bar-graph">
      {_.keys(answers).map((key) => {
        const total = answers[key];
        const width = ((total / totalAnswers) * 100).toFixed(2);
        const nullWidth = isNaN(width);
        const widthPercent = nullWidth ? '0%' : `${width}%`;
        const valueOffset = nullWidth || width < 80 ? 2 : 20;
        const barValuePosition = isNaN(width) ? '0%' : `${width - valueOffset}%`;
        const greaterThanZero = !nullWidth && width > 0;
        return (<div key={key}>
          <div className={`results__bar-graph__row ${(!greaterThanZero ? 'empty' : '')}`}>
            <div className="results__bar-graph__question"><strong>{key}</strong></div>
            <div className="results__bar-graph__bar-row">
              <div className={`results__bar-graph__bar ${(greaterThanZero ? 'active' : '')}`} style={{ height: 20, width: widthPercent, background: '#E5AB28', display: 'inline-block', verticalAlign: 'middle' }} />
              {(greaterThanZero ? <span className="results__bar-graph__bar-value" style={{ position: 'absolute', display: 'inline-block', verticalAlign: 'middle', padding: '0 5px', left: barValuePosition }}>{widthPercent} <span className="total">({total})</span></span> : null)}
            </div>
          </div>
        </div>);
      })}
    </div>
  );
};

BarGraph.propTypes = {
  answers: PropTypes.array.isRequired
};

export default BarGraph;
