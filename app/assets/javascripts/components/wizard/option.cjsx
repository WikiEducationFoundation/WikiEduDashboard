React             = require 'react'
ReactDOM          = require 'react-dom'
md                = require('markdown-it')({ html: true, linkify: true })
WizardActions     = require '../../actions/wizard_actions'

Option = React.createClass(
  displayName: 'Option'
  select: ->
    WizardActions.toggleOptionSelected @props.panel_index, @props.index
  expand: ->
    $(ReactDOM.findDOMNode(@refs.expandable)).toggleHeight()
    WizardActions.toggleOptionExpanded @props.panel_index, @props.index
  render: ->
    disabled = @props.option.min_weeks? && @props.option.min_weeks > @props.open_weeks
    className = 'wizard__option section-header'
    className += ' selected' if @props.option.selected
    className += ' disabled' if disabled
    checkbox = <div className='wizard__option__checkbox'></div> if @props.multiple
    if @props.option.description?
      expand_text = I18n.t('wizard.read_more')
      expand_className = 'wizard__option__description'
      more_className = 'wizard__option__more'
      if @props.option.expanded
        expand_text = I18n.t('wizard.read_less')
        expand_className += ' open'
        more_className += ' open'
      expand = (
        <div className={expand_className} ref='expandable'>
          <div dangerouslySetInnerHTML={{__html: md.render(@props.option.description)}}></div>
        </div>
      )
      expand_link = (
        <button className={more_className} onClick={@expand}><p>{expand_text}</p></button>
      )
    if @props.option.blurb?
      blurb = (
        <div dangerouslySetInnerHTML={{__html: md.render(@props.option.blurb)}}></div>
      )
    if disabled
      notice = <h3>{I18n.t('wizard.min_weeks', {
        min_weeks: @props.option.min_weeks })}</h3>

    <div className={className}>
      <button onClick={@select unless disabled} aria-selected={@props.option.selected || false}>
        {checkbox}
        {notice}
        <h3>{"#{@props.option.title}#{if @props.option.recommended then ' (recommended)' else ''}"}</h3>
        {blurb}
        {expand}
      </button>
      {expand_link}
      <div className='wizard__option__border'></div>
    </div>
)

module.exports = Option
