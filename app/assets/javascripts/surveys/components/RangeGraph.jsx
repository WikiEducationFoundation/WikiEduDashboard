import _ from 'lodash';
import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { answerFrequency } from './utils';

export default class RangeGraph extends Component {
  constructor() {
    super();
    this.state = {
      showValue: null
    };
    this.showValue = this._showValue.bind(this);
  }
  _showValue(val) {
    this.setState({ showValue: val });
  }
  render() {
    const validationRules = this.props.question.validation_rules;
    const min = validationRules.range_minimum;
    const max = validationRules.range_maximum;
    const answers = answerFrequency(this.props);
    const answerKeys = _.keys(answers).sort((a, b) => { return a - b; });
    const mostFrequent = _.values(answers).sort((a, b) => { return a - b; }).pop();
    const graphHeight = mostFrequent * 40;
    const showValue = this.state.showValue;

    const xAxis = () => {
      return (
        <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, width: '100%' }}>
          <span className="results__range-graph__min">{min}</span>
          <span className="results__range-graph__mid">{(max - min) / 2}</span>
          {answerKeys.map(key => {
            const increment = (graphHeight / mostFrequent);
            const xPos = (key / max) * 100;
            const show = showValue === key;
            const value = <div className={`results__range-graph__value ${show ? 'show' : ''}`} style={{ position: 'absolute', left: 0 }}>{key}</div>;
            return (<div key={key} style={{ display: 'inline-block', textAlign: 'center', position: 'absolute', left: `${xPos}%`, bottom: 0 }}>
              {value}
              <div
                className="results__range-graph__bar"
                onMouseEnter={() => { this.showValue(key); }}
                onMouseLeave={() => { this.showValue(null); }}
                style={{ position: 'absolute', display: 'block', width: 10, left: -10, bottom: 0, height: (increment * answers[key]) }}
              />
            </div>);
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
        i++;
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
  }
}

RangeGraph.propTypes = {
  question: PropTypes.object
};
