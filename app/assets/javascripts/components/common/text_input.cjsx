React = require 'react'
InputMixin = require '../../mixins/input_mixin'
Conditional = require '../highlevels/conditional'

TextInput = React.createClass(
  displayName: 'TextInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
  render: ->
    value = @props.value
    if @props.type == 'date'
      v_date = new Date(value)
      month = v_date.getMonth() + 1
      date = v_date.getDate() + 1
      value = month + '/' + date + '/' + v_date.getFullYear()
    if @props.editable
      <input
        value={@state.value}
        onChange={@onChange}
        autoFocus={@props.focus}
        type={@props.type || 'text'}
        placeholder={@props.placeholder}
      />
    else
      <span>{value}</span>
)

module.exports = Conditional(TextInput)
