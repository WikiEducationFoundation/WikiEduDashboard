import React, { useRef } from 'react';
import PropTypes from 'prop-types';
import InputHOC from '../high_order/input_hoc.jsx';
import Conditional from '../high_order/conditional.jsx';

const TextInput = ({
  value,
  value_key,
  editable,
  label,
  placeholder,
  spacer,
  valueClass,
  p_tag_classname,
  inline,
  type,
  max,
  maxLength,
  focus,
  onBlur,
  onClick,
  append,
  onKeyDown,
  _value,
  invalid,
  onChange,
  onFocus,
  id,
  children
}) => {
  const inputRef = useRef(null);

  const onKeyDownHandler = (e) => {
    if (!onKeyDown) return;
    onKeyDown(e.keyCode, inputRef.current);
  };

  // const dateChange = (date) => {
  //   const formattedDate = date ? date.format('YYYY-MM-DD') : '';
  //   return onChange({ target: { value: formattedDate } });
  // };

  let labelContent;
  const usedSpacer = spacer || ': ';

  if (label) {
    labelContent = label + usedSpacer;
  }

  let usedValueClass = 'text-input-component__value ';
  if (valueClass) {
    usedValueClass += valueClass;
  }

  if (editable) {
    let labelClass = '';
    let inputClass = inline ? 'inline' : '';
    if (invalid) {
      labelClass += 'red';
      inputClass += ' invalid';
    }

    let title;
    if (type === 'number') {
      title = I18n.t('accessibility.number_field');
    }

    const className = `${inputClass} ${value_key}`;

    // The default maximum length of 75 ensures that the slug field
    // of a course, which combines three TextInput values, will not exceed
    // the maximum string size of 255.
    const usedMaxLength = maxLength || '75';
    const inputElement = (
      <input
        className={className}
        value={_value !== undefined ? _value : value || ''}
        onChange={onChange}
        autoFocus={focus}
        onFocus={onFocus}
        onBlur={onBlur}
        onKeyDown={onKeyDownHandler}
        type={type || 'text'}
        max={max}
        maxLength={usedMaxLength}
        placeholder={placeholder}
        title={title}
        min={0}
        ref={inputRef}
        aria-labelledby={`${id}-label`}
      />
    );

    return (
      <div className="form-group">
        <label id={`${id}-label`} htmlFor={id} className={labelClass}>
          {labelContent}
        </label>
        {inputElement}
        {children}
      </div>
    );
  } else if (label) {
    return (
      <p className={p_tag_classname}>
        <span className="text-input-component__label">
          <strong>{labelContent}</strong>
        </span>
        <span onBlur={onBlur} onClick={onClick} className={usedValueClass}>
          {value}
        </span>
        {append}
      </p>
    );
  }
  return <span>{value}</span>;
};

TextInput.propTypes = {
  value: PropTypes.any,
  value_key: PropTypes.string,
  editable: PropTypes.bool,
  label: PropTypes.string,
  placeholder: PropTypes.string,
  spacer: PropTypes.string,
  valueClass: PropTypes.string,
  p_tag_classname: PropTypes.string,
  inline: PropTypes.bool,
  type: PropTypes.string,
  max: PropTypes.string,
  maxLength: PropTypes.string,
  focus: PropTypes.func,
  onBlur: PropTypes.func,
  onClick: PropTypes.func,
  append: PropTypes.node,
  onKeyDown: PropTypes.func,
  _value: PropTypes.any,
  // validation: Regex used by Conditional
  // required: bool used by Conditional
};

export default Conditional(InputHOC(TextInput));
