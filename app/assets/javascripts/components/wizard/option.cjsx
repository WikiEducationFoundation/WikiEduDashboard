React             = require 'react/addons'
Checkbox          = require '../common/checkbox'
TextInput         = require '../common/text_input'
TextAreaInput     = require '../common/text_area_input'

Option = React.createClass(
  displayName: 'Option'
  render: ->
    <div className="wizard__option">
      <p><b>{@props.title}</b></p>
      <p><i>{@props.description}</i></p>
    </div>
)

module.exports = Option