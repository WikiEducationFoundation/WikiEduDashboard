
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import _ from 'lodash';
import WizardActions from '../../actions/wizard_actions.js';
import CourseLink from '../common/course_link.jsx';
import Option from './option.jsx';

const md = require('../../utils/markdown_it.js').default();

const Panel = createReactClass({
  displayName: 'Panel',

  propTypes: {
    course: PropTypes.object,
    panel: PropTypes.object,
    saveCourse: PropTypes.func,
    nextEnabled: PropTypes.func,
    index: PropTypes.number,
    rewind: PropTypes.func,
    open_weeks: PropTypes.number,
    raw_options: PropTypes.node,
    advance: PropTypes.func,
    button_text: PropTypes.string,
    helperText: PropTypes.string,
    summary: PropTypes.bool,
    step: PropTypes.string,
    panelCount: PropTypes.number
  },

  persistState() {
      const step = this.props.step.toLowerCase().split(' ').slice(0, 2);
      step[1] = +step[1] + 1; // Keeping the step in line with the UI
      window.history.pushState(
        { index: step[1] - 1 }, // Actual index to be rewinded to
        `Step ${step[1]}`,
        `#${step.join('')}`
      );
      document.title = document.title.replace(/\d+$/, step[1]);
  },

  handlePrevious() {
    window.history.back();
  },

  advance() {
    if (this.props.summary) {
      window.location.hash = `step${this.props.panelCount}`;
      document.title = document.title.replace(/\d+$/, this.props.panelCount); // Sync Title
    }
    else { this.persistState(); }
    if (this.props.saveCourse) {
      if (this.props.saveCourse()) { return WizardActions.advanceWizard(); }
    } else {
      return WizardActions.advanceWizard();
    }
  },

  rewind(e) {
    e.preventDefault();
    this.handlePrevious();
    if (this.props.saveCourse) {
      if (this.props.saveCourse()) { return WizardActions.rewindWizard(); }
    } else {
      return WizardActions.rewindWizard();
    }
  },
  reset(e) {
    e.preventDefault();
    return WizardActions.resetWizard();
  },
  close() {
    return confirm('This will close the wizard without saving your progress. Are you sure you want to do this?');
  },
  nextEnabled() {
    if (!this.props.nextEnabled) { return true; }
    return this.props.nextEnabled();
  },
  render() {
    let rewind;
    let rewindTop;
    if (this.props.index > 0) {
      rewind = <button className="button" onClick={this.rewind}>Previous</button>;
      rewindTop = <a href="" onClick={this.rewind} className="icon icon-left_arrow">Previous</a>;
    }

    const options1 = [];
    const options2 = [];

    if (this.props.panel.options !== undefined) {
      this.props.panel.options.forEach((option, i) => {
        option = (
          <Option
            option={option}
            panel_index={this.props.index}
            key={`${this.props.index}${i}`}
            index={i}
            multiple={this.props.panel.type === 0}
            open_weeks={this.props.open_weeks}
          />
        );
        if (i % 2 === 0) { return options1.push(option); }
        return options2.push(option);
      });
    }

    const options = this.props.raw_options || (
      <div>
        <div className="left">{options1}</div>
        <div className="right">{options2}</div>
      </div>
    );
    let classes = 'wizard__panel';
    if (this.props.panel.active) { classes += ' active'; }
    const advance = this.props.advance || this.advance;

    const nextText = this.props.button_text || (this.props.summary ? 'Summary' : 'Next');


    let reqsMet = true;
    if (this.props.panel.options && this.props.panel.minimum) {
      reqsMet = _.reduce(
        this.props.panel.options, (total, option) => total + (option.selected ? 1 : 0), 0
      ) >= this.props.panel.minimum;
    }

    // panel.type indicates whether multiple selections are allowed or only one.
    // type 1 is single selection; type 0 is multiple selection.
    let reqs;
    if (this.props.panel.minimum) {
      if (this.props.panel.type === 1) {
        reqs = I18n.t('wizard.select_one_option');
      } else if (this.props.panel.type === 0) {
        reqs = I18n.t('wizard.minimum_options', { count: this.props.panel.minimum });
      }
    }

    const helperText = this.props.helperText || '';
    const errorClass = this.props.panel.error ? 'red' : '';
    const nextDisabled = reqsMet && this.nextEnabled() ? '' : 'disabled';
    const courseLink = `/courses/${this.props.course.slug}/timeline`;

    return (
      <div className={classes}>
        <div className="wizard__controls">
          <div className="left">
            {rewindTop}
          </div>
          <div className="right">
            <CourseLink to={courseLink} onClick={this.close}>Close</CourseLink>
          </div>
        </div>
        <h3>{this.props.panel.title}</h3>
        <div dangerouslySetInnerHTML={{ __html: md.render(this.props.panel.description) }} />
        <div className="wizard__panel__options">{options}</div>
        <div className="wizard__panel__controls">
          <div className="left">
            <p>{this.props.step}</p>
          </div>
          <div className="right">
            <div><p className={errorClass}>{this.props.panel.error || reqs}</p></div>
            {rewind}
            <div><p>{helperText}</p></div>
            <button className="button dark" onClick={advance} disabled={nextDisabled}>{nextText}</button>
          </div>
        </div>
      </div>
    );
  }
}
);

export default Panel;
