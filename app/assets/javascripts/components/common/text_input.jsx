import React, { useRef } from 'react';
import PropTypes from 'prop-types';
import InputHOC from '../high_order/input_hoc.jsx';
import Conditional from '../high_order/conditional.jsx';
import { onEnterOrSpace } from '../../utils/keyboard_handlers';

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
  onBlur,
  onClick,
  append,
  onKeyDown,
  _value,
  invalid,
  onChange,
  onFocus,
  id,
  autoComplete,
  children
}) => {
  const inputRef = useRef(null);

  const onKeyDownHandler = (e) => {
    if (!onKeyDown) return;
    onKeyDown(e.keyCode, inputRef.current);
  };

  const labelContent = label ? `${label}${spacer || ': '}` : undefined;

  const usedValueClass = `text-input-component__value ${valueClass ?? ''}`;

  if (editable) {
    const labelClass = invalid ? 'red' : '';
    const inputClass = `${inline ? 'inline' : ''} ${invalid ? 'invalid' : ''}`;

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
        id={id}
        className={className}
        value={_value ?? (value || '')}
        onChange={onChange}
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
        autoComplete={autoComplete}
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
        <span
          role={onClick ? 'button' : undefined}
          tabIndex={onClick ? 0 : undefined}
          onBlur={onBlur}
          onClick={onClick}
          onKeyDown={onClick ? onEnterOrSpace(onClick) : undefined}
          className={usedValueClass}
        >
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
  onBlur: PropTypes.func,
  onClick: PropTypes.func,
  append: PropTypes.node,
  onKeyDown: PropTypes.func,
  _value: PropTypes.any,
  autoComplete: PropTypes.string,
  // validation: Regex used by Conditional
  // required: bool used by Conditional
};

export default Conditional(InputHOC(TextInput));
