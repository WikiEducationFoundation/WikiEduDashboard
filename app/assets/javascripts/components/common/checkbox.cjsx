React = require 'react'
InputMixin = require '../../mixins/input_mixin'

Checkbox = React.createClass(
  displayName: 'Checkbox'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
  onCheckboxChange: (e) ->
    e.target.value = e.target.checked
    @onChange e
  render: ->
    <input
      type="checkbox"
      checked={@state.value}
      onChange={@onCheckboxChange}
      disabled={!@props.editable}
    />
)

module.exports = Checkbox
