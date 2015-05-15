React = require 'react'
Conditional = require '../highlevels/conditional'
InputMixin = require '../../mixins/input_mixin'

Select = React.createClass(
  displayName: 'Select'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
  render: ->
    options = @props.options.map (option, i) =>
      <option value={i} key={i}>{option}</option>

    if @props.editable
      <select
        value={@state.value}
        onChange={@onChange}
      >
        {options}
      </select>
    else
      <span>{@props.options[@props.value]}</span>
)

module.exports = Conditional(Select)
