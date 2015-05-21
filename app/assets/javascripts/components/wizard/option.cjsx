React             = require 'react/addons'
WizardActions     = require '../../actions/wizard_actions'

Option = React.createClass(
  displayName: 'Option'
  selectOption: ->
    WizardActions.selectOption @props.panel_index, @props.index, !@props.option.selected
  render: ->
    className = 'wizard__option half section-header' + (if @props.option.selected then ' selected' else '')
    if @props.multiple
      checkbox = <div className='wizard__option__checkbox'></div>
    <div className={className} onClick={@selectOption}>
      {checkbox}
      <h3>{@props.option.title}</h3>
      <p>{@props.option.description}</p>
      <div className='wizard__option__more'><p>Read More</p></div>
      <div className='wizard__option__border'></div>
    </div>
)

module.exports = Option