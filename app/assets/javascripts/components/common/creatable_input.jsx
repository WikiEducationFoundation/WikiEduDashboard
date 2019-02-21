import React from 'react';
import CreatableSelect from 'react-select/lib/Creatable';
import selectStyles from '../../styles/select';

export default ({ id, label, options, placeholder, onChange }) => {
  return (
    <div>
      <span className="text-input-component__label">
        <strong>{label}</strong>
      </span>
      <CreatableSelect
        id={id}
        onChange={onChange}
        options={options}
        placeholder={placeholder}
        styles={{ ...selectStyles, singleValue: null }}
      />
    </div>
  );
}
;
