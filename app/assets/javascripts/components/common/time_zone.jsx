import React from 'react';

const TimeZone = React.createClass({
  displayName: 'TimeZone',

  propTypes: {
    id: React.PropTypes.string,
    value: React.PropTypes.string,
    value_key: React.PropTypes.string,
    spacer: React.PropTypes.string,
    valueClass: React.PropTypes.string,
    label: React.PropTypes.string,
    editable: React.PropTypes.bool,
    enabled: React.PropTypes.bool,
    p_tag_classname: React.PropTypes.string,
    onChange: React.PropTypes.func,
    append: React.PropTypes.string
  },

  getDefaultProps() {
    return {
      label: I18n.t('courses.time_zone'),
      value: 'UTC'
    };
  },

  /**
   * Update parent component with new timezone.
   * @return {null}
   */
  onChangeHandler(e) {
    this.props.onChange(this.props.value_key, e.target.value);
  },

  getDropdownOptions() {
    return Object.keys(window.TimeZones).map((name, index) => {
      const offset = window.TimeZones[name];
      return (
        <option value={name} key={`timezone-dropdown-${index}`}>
          {`(GMT${offset}) ${name}`}
        </option>
      );
    });
  },

  render() {
    const spacer = this.props.spacer || ': ';
    let label;

    if (this.props.label) {
      label = this.props.label;
      label += spacer;
    }

    let valueClass = 'text-input-component__value ';
    if (this.props.valueClass) { valueClass += this.props.valueClass; }

    if (this.props.editable) {
      return (
        <div className="timezone-input form-group">
          <label htmlFor={`${this.props.id}-timezone`}>
            Time zone:
          </label>
          <select
            id={`${this.props.id}-timezone`}
            className="time-input__zone"
            input
            onChange={this.onChangeHandler}
            value={this.props.value}
            disabled={this.props.enabled && !this.props.enabled}
          >
            {this.getDropdownOptions()}
          </select>
        </div>
      );
    } else if (this.props.label !== null) {
      return (
        <div>
          <p className={this.props.p_tag_classname}>
            <span><strong>Time zone: </strong></span>
            {this.props.value}
          </p>
        </div>
      );
    }

    return (
      <span>{this.value}</span>
    );
  }
});

export default TimeZone;
