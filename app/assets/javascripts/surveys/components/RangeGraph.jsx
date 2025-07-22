import { keys, values } from 'lodash-es';
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { answerFrequency } from './utils';

const RangeGraph = ({ question, answers }) => {
  const [showValue, setShowValue] = useState(null);

  const validationRules = question.validation_rules;
  const min = validationRules.range_minimum;
  const max = validationRules.range_maximum;
  const answerFrequencies = answerFrequency(answers);
  const answerKeys = keys(answerFrequencies).sort((a, b) => { return a - b; });
  const mostFrequent = values(answerFrequencies).sort((a, b) => { return a - b; }).pop();
  const graphHeight = mostFrequent * 40;

  const xAxis = () => {
    return (
      <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, width: '100%' }}>
        <span className="results__range-graph__min">{min}</span>
        <span className="results__range-graph__mid">{(max - min) / 2}</span>
        {answerKeys.map((key) => {
          const increment = (graphHeight / mostFrequent);
          const xPos = (key / max) * 100;
          const show = showValue === key;
          const value = <div className={`results__range-graph__value ${show ? 'show' : ''}`} style={{ position: 'absolute', left: 0 }}>{key}</div>;
          return (
            <div key={key} style={{ display: 'inline-block', textAlign: 'center', position: 'absolute', left: `${xPos}%`, bottom: 0 }}>
              {value}
              <div
                className="results__range-graph__bar"
                onMouseEnter={() => { setShowValue(key); }}
                onMouseLeave={() => { setShowValue(null); }}
                style={{ position: 'absolute', display: 'block', width: 10, left: -10, bottom: 0, height: (increment * answerFrequencies[key]) }}
              />
            </div>
          );
        })}
        <span className="results__range-graph__max">{max}</span>
      </div>
    );
  };

  const yAxis = () => {
    let i = 0;
    const increment = (graphHeight / mostFrequent) - 1;
    const yRows = [];
    while (i < mostFrequent) {
      i += 1;
      yRows.push(
        <div key={`row${i}`} style={{ position: 'relative', height: increment }} className="results__range-graph__row">
          <div style={{ position: 'absolute', height: 15, top: -8, left: -20 }}>{mostFrequent - (i - 1)}</div>
        </div>
      );
    }
    return yRows;
  };

  return (
    <div>
      <span className="contextual">Frequency</span>
      <div style={{ padding: '20px 0 20px 20px' }}>
        <div className="results__range-graph" style={{ position: 'relative', width: '100%', height: graphHeight }}>
          {yAxis()}
          {xAxis()}
        </div>
      </div>
      <div className="text-center p1"><span className="contextual">Values</span></div>
    </div>
  );
};

RangeGraph.propTypes = {
  question: PropTypes.object,
  answers: PropTypes.array
};

export default (RangeGraph);
