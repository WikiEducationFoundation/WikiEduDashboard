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
    if @props.label
      label = <span>{@props.label + ': '}</span>
    <p className={@props.container_class}>
      {label}
      <input
        type="checkbox"
        checked={@state.value}
        onChange={@onCheckboxChange}
        disabled={!@props.editable}
      />
    </p>
)

module.exports = Checkbox
