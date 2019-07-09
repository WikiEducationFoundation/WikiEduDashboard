import React from 'react';

const createReactClass = require('create-react-class');

const AcademicSystem = createReactClass({

  getInitialState: function () {
    return {
      selectedOption: 'Semester'
    };
  },

  handleChange: function () {
    this.props.onChange(this.props.myValue);
  },

  render: function () {
    const options = ['Semester', 'Quarter'];
    let i;
    const academic_system = [];
    for (i = 0; i < options.length; i += 1) {
      academic_system.push(
        <label>
          <input type = "radio" name="academic_system" defaultChecked={this.state.selectedOption === options[i]} onChange={this.handleOptionChange}/>
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
