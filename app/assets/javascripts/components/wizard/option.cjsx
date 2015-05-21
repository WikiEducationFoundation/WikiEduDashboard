React             = require 'react/addons'
WizardActions     = require '../../actions/wizard_actions'

Option = React.createClass(
  displayName: 'Option'
  select: ->
    WizardActions.toggleOptionSelected @props.panel_index, @props.index
  expand: ->
    WizardActions.toggleOptionExpanded @props.panel_index, @props.index
  render: ->
    className = 'wizard__option half section-header'
    className += ' selected' if @props.option.selected
    checkbox = <div className='wizard__option__checkbox'></div> if @props.multiple
    expand_text = 'Read More'
    expand_className = 'wizard__option__description'
    if @props.option.expanded
      expand_text = 'Read Less'
      expand_className += ' open'

    <div className={className}>
      <div onClick={@select}>
        {checkbox}
        <h3>{@props.option.title}</h3>
        <p>{@props.option.blurb}</p>
        <div className={expand_className}>
          <p>{@props.option.description}</p>
        </div>
      </div>
      <div className='wizard__option__more' onClick={@expand}><p>{expand_text}</p></div>
      <div className='wizard__option__border'></div>
    </div>
)

module.exports = Option