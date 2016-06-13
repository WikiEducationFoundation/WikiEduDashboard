React = require 'react'
OnClickOutside = require 'react-onclickoutside'
DayPicker = require 'react-day-picker'
InputMixin = require '../../mixins/input_mixin.cjsx'
Conditional = require '../high_order/conditional.cjsx'

DatePicker = React.createClass(
  displayName: 'DatePicker'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
    datePickerVisible: false
  componentWillReceiveProps: (nextProps) ->
    unless @state.value?
      @setState value: nextProps.value
  handleDatePickerChange: (e, selectedDate) ->
    date = moment(selectedDate).format("YYYY-MM-DD")
    @onChange({ target: { value: date } })
    @setState({ datePickerVisible: false })
  handleDateFieldChange: (e) ->
    value = e.target.value
    @onChange({ target: { value: value } })
  handleClickOutside: (e) ->
    if @state.datePickerVisible
      @setState
        datePickerVisible: false
  handleDateFieldClick: (e) ->
    unless @state.datePickerVisible
      @setState
        datePickerVisible: true
  handleDateFieldFocus: (e) ->
    @setState
      datePickerVisible: true
  handleDateFieldBlur: (e) ->
    if @state.datePickerVisible
      @refs.datefield.focus()
  handleDateFieldKeyDown: (e) ->
    # Close picker if tab, enter, or escape
    if _.includes [9, 13, 27], e.keyCode
      @setState
        datePickerVisible: false
  isDaySelected: (date) ->
    currentDate = moment(date).format('YYYY-MM-DD')
    return currentDate == @state.value
  showCurrentDate: ->
    this.refs.daypicker.showMonth(@state.month)
  render: ->
    spacer = @props.spacer || ': '
    
    if @props.label
      label = @props.label
      label += spacer
    value = @props.value

    valueClass = 'text-input-component__value '
    valueClass += @props.valueClass if @props.valueClass

    if @props.editable
      labelClass = ''
      inputClass = if @props.inline? && @props.inline then ' inline' else ''
      
      if @state.invalid
        labelClass += 'red'
        inputClass += 'invalid'

      date = moment(@state.value, "YYYY-MM-DD")

      if date.isValid()
        currentMonth = date.toDate()
      else 
        currentMonth = new Date()

      modifiers = 
        selected: @isDaySelected

      input = (
        <div className='date-input'>
          <input 
            id={@props.id || ''}
            ref='datefield'
            value={@state.value} 
            className={"#{inputClass} #{@props.value_key}"}
            onChange={@handleDateFieldChange} 
            onClick={@handleDateFieldClick}
            disabled={@props.enabled? && !@props.enabled}
            autoFocus={@props.focus}
            isClearable={if @props.isClearable? then @props.isClearable else false}
            onFocus={@handleDateFieldFocus}
            onBlur={@handleDateFieldBlur}
            onKeyDown={@handleDateFieldKeyDown}
            placeholder={@props.placeholder}
          /> 
          <DayPicker
            className={'DayPicker--visible ignore-react-onclickoutside' if @state.datePickerVisible}
            ref='daypicker'
            tabIndex={-1}
            modifiers={modifiers}
            onDayClick={@handleDatePickerChange}
            initialMonth={currentMonth}
          />
        </div>
      )

      <div className={"#{inputClass} input_wrapper"}>
        <label className={labelClass}>{label}</label>
        {spacer if (@props.value? or @props.editable) && !@props.label}
        {input}
      </div>
    else if @props.label
      <p className={@props.p_tag_classname}>
        <span className="text-input-component__label">{label}</span>
        <span>{spacer if (@props.value? or @props.editable) && !@props.label}</span>
        <span onBlur={@props.onBlur} onClick={@props.onClick} className={valueClass}>{value}</span>
        {@props.append}
      </p>
    else
      <span>{value}</span>
)

module.exports = Conditional(OnClickOutside(DatePicker))
