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
    value = if date? then date.format('YYYY-MM-DD') else null
    @shouldDisableSave = false
    if _.has(@props, 'disableSave')
      @shouldDisableSave = value is null
    @onChange({ target: { value: value } })
    @props.disableSave(true) if @shouldDisableSave
  render: ->
    spacer = @props.spacer || ': '
    if @props.label
      label = @props.label
      label += spacer
    value = @props.value

    if @props.editable
      labelClass = ''
      inputClass = if @props.inline? && @props.inline then ' inline' else ''
      if @state.invalid
        labelClass += 'red'
        inputClass += 'invalid'

      if @props.type == 'number'
        title = 'This is a number field. The buttons rendered by most browsers will increment and decrement the input.'

      if @props.type == 'date'
        # Note: normally we want an onBlur={@blur} prop on the DatePicker
        # it's missing due to a bug in react-datepicker (#158)
        input = (
          <DatePicker
            ref='input'
            className={"#{inputClass} #{@props.value_key}"}
            id={@props.id || ''}
            selected={if @state.value? then moment(@state.value) else null}
            onChange={@dateChange}
            autoFocus={@props.focus}
            onFocus={@focus}
            placeholderText={@props.placeholder}
            weekStart="0"
            disabled={@props.enabled? && !@props.enabled}
            isClearable={if @props.isClearable? then @props.isClearable else false}
            {...@props.date_props}
          />
        )
      else
        input = (
          <input
            ref='input'
            className={"#{inputClass} #{@props.value_key}"}
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

      <label className={"#{inputClass}#{if @props.type == 'date' then ' input_wrapper' else ''}"}>
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
