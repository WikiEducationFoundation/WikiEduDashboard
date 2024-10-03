import React from 'react';
import PropTypes from 'prop-types';
import { reduce } from 'lodash-es';
import Option from './option.jsx';

const md = require('../../utils/markdown_it.js').default();

const Panel = (props) => {
  const persistState = () => {
    const step = props.step.toLowerCase().split(' ').slice(0, 2);
    step[1] = +step[1] + 1; // Keeping the step in line with the UI
    window.history.pushState(
      { index: step[1] - 1 }, // Actual index to be rewinded to
      `Step ${step[1]}`,
      `#${step.join('')}`
    );
    document.title = document.title.replace(/\d+$/, step[1]);
  };

  const advance = () => {
    if (props.summary) {
      window.location.hash = `step${props.panelCount}`;
      document.title = document.title.replace(/\d+$/, props.panelCount); // Sync Title
      return props.goToWizard(props.panelCount - 1);
    }
    persistState();
    if (props.saveCourse) {
      if (props.saveCourse()) { return props.advance(); }
    } else {
      return props.advance();
    }
  };

  const rewinds = () => {
    if (props.rewind) {
      props.rewind();
    } else {
      window.history.back();
    }
  };

  // const close = ()=>{
  //   return confirm('This will close the wizard without saving your progress. Are you sure you want to do this?');
  // };

  const nextEnabled = () => {
    if (!props.nextEnabled) { return true; }
    return props.nextEnabled();
  };

  let rewind;
  if (props.index > 0) {
    rewind = <button className="button" onClick={rewinds}>Previous</button>;
  }

  const options1 = [];
  const options2 = [];

  if (props.panel.options !== undefined) {
    props.panel.options.forEach((option, i) => {
      option = (
        <Option
          option={option}
          panel_index={props.index}
          key={`${props.index}${i}`}
          index={i}
          multiple={props.panel.type === 0}
          open_weeks={props.open_weeks}
          selectWizardOption={props.selectWizardOption}
        />
      );
      if (i % 2 === 0) { return options1.push(option); }
      return options2.push(option);
    });
  }

  const options = props.raw_options || (
    <div>
      <div className="left">{options1}</div>
      <div className="right">{options2}</div>
    </div>
  );
  let classes = 'wizard__panel';
  if (props.active) { classes += ' active'; }

  const nextText = props.button_text || (props.summary ? 'Summary' : 'Next');


  let reqsMet = true;
  if (props.panel.options && props.panel.minimum) {
    reqsMet = reduce(
      props.panel.options, (total, option) => total + (option.selected ? 1 : 0), 0
    ) >= props.panel.minimum;
  }

  // panel.type indicates whether multiple selections are allowed or only one.
  // type 1 is single selection; type 0 is multiple selection.
  let reqs;
  if (props.panel.minimum) {
    if (props.panel.type === 1) {
      reqs = I18n.t('wizard.select_one_option');
    } else if (props.panel.type === 0) {
      reqs = I18n.t('wizard.minimum_options', { count: props.panel.minimum });
    }
  }

  const helperText = props.helperText || '';
  const errorClass = props.panel.error ? 'red' : '';
  const nextDisabled = reqsMet && nextEnabled() ? '' : 'disabled';

  return (
    <div className={classes}>
      <h3>{props.panel.title}</h3>
      <div dangerouslySetInnerHTML={{ __html: md.render(props.panel.description) }} />
      <div className="wizard__panel__options">{options}</div>
      <div className="wizard__panel__controls">
        <div className="left">
          <p>{props.step}</p>
        </div>
        <div className="right">
          <div><p className={errorClass}>{props.panel.error || reqs}</p></div>
          {rewind}
          <div><p>{helperText}</p></div>
          <button className="button dark" onClick={advance} disabled={nextDisabled}>{nextText}</button>
        </div>
      </div>
    </div>
  );
};
Panel.displayName = 'Panel';

Panel.propTypes = {
  course: PropTypes.object,
  panel: PropTypes.object,
  active: PropTypes.bool.isRequired,
  saveCourse: PropTypes.func,
  nextEnabled: PropTypes.func,
  index: PropTypes.number,
  open_weeks: PropTypes.number,
  raw_options: PropTypes.node,
  advance: PropTypes.func.isRequired,
  rewind: PropTypes.func,
  button_text: PropTypes.string,
  helperText: PropTypes.string,
  summary: PropTypes.bool,
  step: PropTypes.string,
  panelCount: PropTypes.number,
  selectWizardOption: PropTypes.func.isRequired
};

export default Panel;
