import React, { useState } from 'react';

const AcademicSystem = (props) => {
  const [selectedOption, setSelectedOption] = useState(props.value || 'semester');

  const handleOptionChange = (changeEvent) => {
    setSelectedOption(changeEvent.target.value);
    props.updateCourseProps({ academic_system: changeEvent.target.value });
  };

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
          defaultChecked={selectedOption === options[i]}
          onChange={handleOptionChange}
        />
        {options[i]}
      </label>);
  }
  return (
    <div>
      {academic_system}
    </div>
  );
};

export default AcademicSystem;
