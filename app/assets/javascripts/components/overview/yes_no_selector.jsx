import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
import Select from 'react-select';
import selectStyles from '../../styles/single_select';

const YesNoSelector = createReactClass({
  propTypes: {
    courseProperty: PropTypes.string.isRequired,
    label: PropTypes.string.isRequired,
    tooltip: PropTypes.string,
    course: PropTypes.object.isRequired,
    editable: PropTypes.bool,
    updateCourse: PropTypes.func.isRequired
  },

  getInitialState() {
    const initialState = this.props.course[this.props.courseProperty] ? I18n.t('application.opt_yes') : I18n.t('application.opt_no');
    return { selectedOption: { value: initialState, label: initialState } };
  },

  _handleChange(selectedOption) {
    const course = this.props.course;
    const value = selectedOption.value;
    this.setState({ selectedOption });
    if (value === I18n.t('application.opt_yes')) {
      course[this.props.courseProperty] = true;
    } else if (value === I18n.t('application.opt_no')) {
      course[this.props.courseProperty] = false;
    }
    return this.props.updateCourse(course);
  },

  render() {
    const currentValue = this.props.course[this.props.courseProperty];
    let selector = (
      <span>
        <strong>{this.props.label}:</strong> {currentValue ? I18n.t('application.opt_yes') : I18n.t('application.opt_no')}
      </span>
    );
    if (this.props.editable) {
      let tooltip;
      if (this.props.tooltip) {
        tooltip = (
          <div className="tooltip-trigger">
            <img src ="/assets/images/info.svg" alt = "tooltip default logo" />
            <div className="tooltip large dark">
              <p>
                {this.props.tooltip}
              </p>
            </div>
          </div>
        );
      }
      const options = [
        { value: I18n.t('application.opt_yes'), label: I18n.t('application.opt_yes') },
        { value: I18n.t('application.opt_no'), label: I18n.t('application.opt_no') }
      ];
      selector = (
        <div className="form-group">
          <label
            id={`${this.props.courseProperty}-label`}
            className="inline-label"
            htmlFor={`${this.props.courseProperty}Toggle`}
          >
            <strong>{this.props.label}:</strong>
          </label>
          {tooltip}
          <Select
            id={`${this.props.courseProperty}Toggle`}
            name={this.props.courseProperty}
            value={options.find(option => option.value === this.state.selectedOption.value)}
            onChange={this._handleChange}
            options={options}
            styles={selectStyles}
            aria-labelledby={`${this.props.courseProperty}-label`}
          />
        </div>
      );
    }
    return (
      <div className={`${this.props.courseProperty}_selector`}>
        {selector}
      </div>
    );
  }

});

export default YesNoSelector;
