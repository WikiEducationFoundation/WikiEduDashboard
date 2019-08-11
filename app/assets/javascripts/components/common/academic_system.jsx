import React from 'react';

const createReactClass = require('create-react-class');

const AcademicSystem = createReactClass({

  getInitialState: function () {
    console.log(this.props);
    return {
      selectedOption: this.props.value || 'Semester'
    };
  },

  handleOptionChange: function (changeEvent) {
    this.setState({
      selectedOption: changeEvent.target.value
    });
    this.props.updateCourseProps({ academic_system: changeEvent.target.value });
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
