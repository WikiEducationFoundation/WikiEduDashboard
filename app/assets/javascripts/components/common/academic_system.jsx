import React from 'react';

const createReactClass = require('create-react-class');

const AcademicSystem = createReactClass({

  getInitialState: function () {
    this.props.updateCourseProps({ academic_system: this.props.value || 'semester' });
    return {
      selectedOption: this.props.value || 'semester'
    };
  },

  handleOptionChange: function (changeEvent) {
    this.setState({
      selectedOption: changeEvent.target.value
    });
    this.props.updateCourseProps({ academic_system: changeEvent.target.value });
  },

  render: function () {
    const options = ['semester', 'quarter', 'other'];
    let i;
    const academic_system = [];
    for (i = 0; i < options.length; i += 1) {
      academic_system.push(
        <label className="radio-inline" key={options[i]}>
          <input
            type="radio"
            name="academic_system"
            value={options[i]}
            style={{ display: 'inline-block', width: '30px' }}
            defaultChecked={this.state.selectedOption === options[i]}
            onChange={this.handleOptionChange}
          />
          {options[i]}
        </label>);
    }
    return (
      <div>
        {academic_system}
      </div>
    );
  }
});

export default AcademicSystem;
