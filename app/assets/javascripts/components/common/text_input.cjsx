React = require 'react'
DatePicker = require 'react-datepicker'
InputMixin = require '../../mixins/input_mixin'
Conditional = require '../high_order/conditional'

TextInput = React.createClass(
  displayName: 'TextInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
  componentWillReceiveProps: (nextProps) ->
    unless @state.value?
      @setState value: nextProps.value
  dateChange: (date) ->
    @onChange({ target: { value: date.format('YYYY-MM-DD') } })
  render: ->
    spacer = @props.spacer || ': '
    if @props.label
      label = @props.label
      label += spacer
    value = @props.value

    if @props.editable
      labelClass = ''
      inputClass = ''
      if @state.invalid
        labelClass = 'red'
        inputClass = 'invalid'

      if @props.type == 'number'
        title = 'This is a number field. The buttons rendered by most browsers will increment and decrement the input.'

      if @props.type == 'date' && (@state.value? || @props.blank)
        input = (
          <DatePicker
            ref='input'
            className={inputClass}
            id={@props.id || ''}
            selected={if @state.value? then moment(@state.value) else null}
            onChange={@dateChange}
            autoFocus={@props.focus}
            onFocus={@focus}
            onBlur={@blur}
            placeholderText={@props.placeholder}
            weekStart="0"
            disabled={@props.enabled? && !@props.enabled}
            {...@props.date_props}
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
            placeholder={@props.placeholder}
            title={title}
            disabled={@props.enabled? && !@props.enabled}
            min=0
          />
        )

      <label className={inputClass}>
        <span className={labelClass}>{label}</span>
        {spacer if (@props.value? or @props.editable) && !@props.label}
        {input}
      </label>
    else if @props.label
      <p>
        <span>{label}</span>
        {spacer if (@props.value? or @props.editable) && !@props.label}
        <span>{value}</span>
        {@props.append}
      </p>
    else
      <span>{value}</span>
)

module.exports = Conditional(TextInput)
