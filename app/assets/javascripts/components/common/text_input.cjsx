React = require 'react'
DatePicker = require 'react-datepicker'
InputMixin = require '../../mixins/input_mixin'
Conditional = require '../highlevels/conditional'

TextInput = React.createClass(
  displayName: 'TextInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: if @props.value? then @props.value else moment().format('YYYY-MM-DD')
  dateChange: (date) ->
    @onChange({ target: { value: date.format('YYYY-MM-DD') } })
  render: ->
    spacer = @props.spacer || ': '
    if @props.label
      label = @props.label
      label += spacer
    value = @props.value || @props.placeholder

    if @props.editable
      labelClass = ''
      inputClass = ''
      if @props.invalid
        labelClass = 'red'
        inputClass = 'invalid'

      if @props.type == 'date'
        v_date = if value? then moment(value) else moment()
        value = v_date.format('YYYY-MM-DD')
        input = (
          <DatePicker
            ref='input'
            className={inputClass}
            id={@props.id || ''}
            selected={moment(@state.value)}
            onChange={@dateChange}
            autoFocus={@props.focus}
            onFocus={@focus}
            onBlur={@blur}
            placeholderText={@props.label || @props.placeholder}
          />
        )
      else
        input = (
          <input
            ref='input'
            className={inputClass}
            id={@props.id || ''}
            value={@state.value}
            onChange={@onChange}
            autoFocus={@props.focus}
            onFocus={@focus}
            onBlur={@blur}
            type={@props.type || 'text'}
            placeholder={@props.label || @props.placeholder}
          />
        )

      <label>
        <span className={labelClass}>{label}</span>
        {spacer if (@props.value? or @props.placeholder? or @props.editable) && !@props.label}
        {input}
      </label>
    else if @props.label
      <p>
        <span>{label}</span>
        {spacer if (@props.value? or @props.placeholder? or @props.editable) && !@props.label}
        <span>{value}</span>
        {@props.append}
      </p>
    else
      <span>{value}</span>
)

module.exports = Conditional(TextInput)
