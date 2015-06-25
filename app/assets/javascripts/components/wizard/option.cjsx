React             = require 'react/addons'
WizardActions     = require '../../actions/wizard_actions'

Option = React.createClass(
  displayName: 'Option'
  select: ->
    WizardActions.toggleOptionSelected @props.panel_index, @props.index
  expand: ->
    $(React.findDOMNode(@refs.expandable)).toggleHeight()
    WizardActions.toggleOptionExpanded @props.panel_index, @props.index
  render: ->
    className = 'wizard__option section-header'
    className += ' selected' if @props.option.selected
    checkbox = <div className='wizard__option__checkbox'></div> if @props.multiple
    if @props.option.description
      expand_text = 'Read More'
      expand_className = 'wizard__option__description'
      more_className = 'wizard__option__more'
      if @props.option.expanded
        expand_text = 'Read Less'
        expand_className += ' open'
        more_className += ' open'
      expand = (
        <div className={expand_className} ref='expandable'>
          <p>{@props.option.description}</p>
        </div>
      )
      expand_link = (
        <button className={more_className} onClick={@expand}><p>{expand_text}</p></button>
      )

    <div className={className}>
      <button onClick={@select}>
        {checkbox}
        <h3>{@props.option.title}</h3>
        <p>{@props.option.blurb}</p>
        {expand}
      </button>
      {expand_link}
      <div className='wizard__option__border'></div>
    </div>
)

module.exports = Option