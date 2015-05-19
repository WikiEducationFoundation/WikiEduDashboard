React             = require 'react/addons'
Checkbox          = require '../common/checkbox'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'

Option = React.createClass(
  displayName: 'Option'
  selectOption: ->
    @props.selectOption()
  render: ->
    className = 'wizard__option section-header' + (if @props.selected then ' selected' else '')
    if @props.multiple
      checkbox = <div className='wizard__option__checkbox'></div>
    <div className={className} onClick={@selectOption}>
      {checkbox}
      <h3>{@props.title}</h3>
      <p>{@props.description}</p>
    </div>
)

module.exports = Option