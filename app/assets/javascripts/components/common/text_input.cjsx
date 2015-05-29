React = require 'react'
InputMixin = require '../../mixins/input_mixin'
Conditional = require '../highlevels/conditional'

TextInput = React.createClass(
  displayName: 'TextInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
  render: ->
    spacer = @props.spacer || <span>: </span>
    if @props.label
      label = @props.label
    value = @props.value
    if @props.type == 'date'
      v_date = moment(value)
      value = v_date.format('YYYY-MM-DD')
    if @props.editable
      labelClass = ''
      inputClass = ''
      if @props.invalid
        labelClass = 'red'
        inputClass = 'invalid'
      <label>
        <span className={labelClass}>{label}</span>
        {spacer if @props.value? or @props.editable}
        <input
          className={inputClass}
          id={@props.id}
          value={@state.value}
          onChange={@onChange}
          autoFocus={@props.focus}
          type={@props.type || 'text'}
          placeholder={@props.label || @props.placeholder}
        />
      </label>
    else if @props.label
      <p>
        <span>{label}</span>
        {spacer if @props.value? or @props.editable}
        <span>{value}</span>
      </p>
    else
      <span>{value}</span>
)

module.exports = Conditional(TextInput)
