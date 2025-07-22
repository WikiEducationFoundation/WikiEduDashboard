import React, { useRef } from 'react';
import PropTypes from 'prop-types';

const md = require('../../utils/markdown_it.js').default();

const Option = ({
  index,
  panel_index,
  option,
  open_weeks,
  multiple,
  selectWizardOption
}) => {
  const descriptionRef = useRef(null);

  const select = () => {
    if (option.required) { return; }
    return selectWizardOption(panel_index, index);
  };

  const expand = () => {
    descriptionRef?.current?.classList.toggle('open');
  };

  const disabled = option.min_weeks && option.min_weeks > open_weeks;
  let className = 'wizard__option section-header';
  if (option.small) {
    className += ' wizard__option__small';
  }
  if (option.selected) { className += ' selected'; }
  if (disabled) { className += ' disabled'; }

  let checkbox;
  if (multiple) { checkbox = <div className="wizard__option__checkbox" />; }

  let expandContent;
  let expandLink;
  if (option.description) {
    let expandText = I18n.t('wizard.read_more');
    let expandClassName = 'wizard__option__description';
    let moreClassName = 'wizard__option__more';
    if (option.expanded) {
      expandText = I18n.t('wizard.read_less');
      expandClassName += ' open';
      moreClassName += ' open';
    }
    expandContent = (
      <div className={expandClassName} ref={descriptionRef}>
        <div dangerouslySetInnerHTML={{ __html: md.render(option.description) }} />
      </div>
    );
    expandLink = (
      <button className={moreClassName} onClick={expand}><p>{expandText}</p></button>
    );
  }

  let blurb;
  if (option.blurb) {
    blurb = (
      <div dangerouslySetInnerHTML={{ __html: md.render(option.blurb) }} />
    );
  }

  let notice;
  if (disabled) {
    notice = (
      <h3>
        {I18n.t('wizard.min_weeks', { min_weeks: option.min_weeks })}
      </h3>
    );
  }

  let onClick;
  if (!disabled) { onClick = select; }

  return (
    <div className={className}>
      <button onClick={onClick} role="checkbox" aria-checked={option.selected || false}>
        {checkbox}
        {notice}
        <h3>{option.title}</h3>
        {blurb}
        {expandContent}
      </button>
      {expandLink}
      <div className="wizard__option__border" />
    </div>
  );
};

Option.propTypes = {
  index: PropTypes.number.isRequired,
  panel_index: PropTypes.number.isRequired,
  option: PropTypes.object.isRequired,
  open_weeks: PropTypes.number.isRequired,
  multiple: PropTypes.bool,
  selectWizardOption: PropTypes.func.isRequired
};

export default Option;
