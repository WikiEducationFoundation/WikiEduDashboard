import _ from 'lodash';
import React, { Component } from 'react';
import { answerFrequency } from './utils';
import _sortedUniqBy from 'lodash.sorteduniqby';

export default class RangeGraph extends Component {
  render() {
    // const { data } = this.props;
    const graphHeight = 300;
    const answers = answerFrequency(this.props);
    const answerKeys = _sortedUniqBy(_.keys(answers));
    const mostFrequent = _sortedUniqBy(_.values(answers)).pop();
    // const totalAnswers = this.props.answers.length;
    function xAxis() {
      return (<div style={{ position: 'absolute', bottom: 0, left: 0, right: 0 }}>
      {answerKeys.map(key => {
        const width = `${(100 / answerKeys.length)}%`;
        const increment = (graphHeight / mostFrequent);
        return (<div key={key} style={{ display: 'inline-block', textAlign: 'center', width, position: 'relative' }}>
          <div style={{ position: 'relative', bottom: -25 }}>{key}</div>
          <div style={{ position: 'absolute', left: '50%', background: 'tomato', display: 'block', width: 5, bottom: 0, marginLeft: -2.5, height: (increment * answers[key]) - 1 }} />
        </div>);
      })}</div>);
    }
    function yAxis() {
      let i = 0;
      const increment = (graphHeight / mostFrequent) - 1;
      const yRows = [];
      while (i < mostFrequent) {
        i++;
        yRows.push(<div key={`row${i}`} style={{ position: 'relative', height: increment, borderTop: '1px solid black' }}>
        <div style={{ position: 'absolute', height: 15, top: -8, left: -20 }}>{mostFrequent - (i - 1)}</div>
        </div>);
      }
      return yRows;
    }

    return (
      <div style={{ padding: 20 }}>
      <div style={{ position: 'relative', width: '100%', height: graphHeight, background: 'rgba(0,0,0,.1)' }}>
        {yAxis()}
        {xAxis()}
      </div>
      </div>
    );
  }
}
