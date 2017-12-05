import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';
const md = require('../../utils/markdown_it.js').default();
import WizardActions from '../../actions/wizard_actions.js';

const Option = createReactClass({
  displayName: 'Option',

  propTypes: {
    index: PropTypes.number.isRequired,
    panel_index: PropTypes.number.isRequired,
    option: PropTypes.object.isRequired,
    open_weeks: PropTypes.number.isRequired,
    multiple: PropTypes.bool
  },

  select() {
    return WizardActions.toggleOptionSelected(this.props.panel_index, this.props.index);
  },

  expand() {
    $(this.expandable).slideToggle();
    return WizardActions.toggleOptionExpanded(this.props.panel_index, this.props.index);
  },

  render() {
    const disabled = this.props.option.min_weeks && this.props.option.min_weeks > this.props.open_weeks;
    let className = 'wizard__option section-header';
    if (this.props.option.selected) { className += ' selected'; }
    if (disabled) { className += ' disabled'; }

    let checkbox;
    if (this.props.multiple) { checkbox = <div className="wizard__option__checkbox" />; }

    let expand;
    let expandLink;
    if (this.props.option.description) {
      let expandText = I18n.t('wizard.read_more');
      let expandClassName = 'wizard__option__description';
      let moreClassName = 'wizard__option__more';
      if (this.props.option.expanded) {
        expandText = I18n.t('wizard.read_less');
        expandClassName += ' open';
        moreClassName += ' open';
      }
      expand = (
        <div className={expandClassName} ref={(div) => this.expandable = div}>
          <div dangerouslySetInnerHTML={{ __html: md.render(this.props.option.description) }} />
        </div>
      );
      expandLink = (
        <button className={moreClassName} onClick={this.expand}><p>{expandText}</p></button>
      );
    }

    let blurb;
    if (this.props.option.blurb) {
      blurb = (
        <div dangerouslySetInnerHTML={{ __html: md.render(this.props.option.blurb) }} />
      );
    }

    let notice;
    if (disabled) {
      notice = (
        <h3>
          {I18n.t('wizard.min_weeks', { min_weeks: this.props.option.min_weeks })}
        </h3>
      );
    }

    const title = `${this.props.option.title}${this.props.option.recommended ? ' (recommended)' : ''}`;

    let onClick;
    if (!disabled) { onClick = this.select; }

    return (
      <div className={className}>
        <button onClick={onClick} role="checkbox" aria-checked={this.props.option.selected || false}>
          {checkbox}
          {notice}
          <h3>{title}</h3>
          {blurb}
          {expand}
        </button>
        {expandLink}
        <div className="wizard__option__border" />
      </div>
    );
  }
});

export default Option;
