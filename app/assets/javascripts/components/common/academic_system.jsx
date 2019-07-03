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
    return (
      <div>
        <label>
          <input type = "radio" name="academic_system" defaultChecked={this.state.selectedOption === 'Semester'} onChange={this.handleOptionChange}/>
          Semester
        </label>
        <label>
          <input type = "radio" name="academic_system" defaultChecked={this.state.selectedOption === 'Quarter'} onChange={this.handleOptionChange}/>
          Quarter
        </label>
      </div>
    );
  }
});

export default AcademicSystem;
