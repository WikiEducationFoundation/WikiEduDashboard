import React, { useState } from 'react';
import CreatableSelect from 'react-select/creatable';
import selectStyles from '../../styles/select';

const CreatableInput = (props) => {
  const [selected, setSelected] = useState();
  const { label, id, options, placeholder } = props;

  const onModify = ({ value }) => {
    if (value) {
      setSelected({ label: value, value });
      props.onChange({ value });
    }
  };

  return (
    <div>
      <span className="text-input-component__label">
        <strong>{label}</strong>
      </span>
      <CreatableSelect
        id={id}
        onChange={onModify}
        onBlur={element => onModify({ value: element.target.value })}
        options={options}
        placeholder={placeholder}
        value={selected}
        styles={{ ...selectStyles, singleValue: null }}
      />
    </div>
  );
};


export default CreatableInput;
