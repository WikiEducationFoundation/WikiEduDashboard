import _ from 'lodash';
import React, { Component } from 'react';
import { answerFrequency } from './utils';

export default class RangeGraph extends Component {
  render() {
    const answers = answerFrequency(this.props);
    const answerKeys = _.keys(answers).sort((a, b) => { return a - b; });
    const mostFrequent = _.values(answers).sort((a, b) => { return a - b; }).pop();
    const graphHeight = mostFrequent * 40;
    const max = answerKeys[answerKeys.length - 1];

    function xAxis() {
      return (<div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, width: '100%' }}>
      {answerKeys.map(key => {
        const increment = (graphHeight / mostFrequent);
        const xPos = (key / max) * 100;
        const value = <div className="results__range-graph__value" style={{ position: 'absolute', bottom: -25, left: -7.5 }}>{key}</div>;
        return (<div key={key} style={{ display: 'inline-block', textAlign: 'center', position: 'absolute', left: `${xPos}%`, bottom: 0 }}>
          {value}
          <div className="results__range-graph__bar" style={{ position: 'absolute', display: 'block', width: 5, left: -5, bottom: 0, height: (increment * answers[key]) - 1 }} />
        </div>);
      })}</div>);
    }
    function yAxis() {
      let i = 0;
      const increment = (graphHeight / mostFrequent) - 1;
      const yRows = [];
      while (i < mostFrequent) {
        i++;
        yRows.push(<div key={`row${i}`} style={{ position: 'relative', height: increment }} className="results__range-graph__row">
        <div style={{ position: 'absolute', height: 15, top: -8, left: -20 }}>{mostFrequent - (i - 1)}</div>
        </div>);
      }
      return yRows;
    }

    // function

    return (
      <div>
      <span className="contextual">Frequency</span>
      <div style={{ padding: 20 }}>
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
