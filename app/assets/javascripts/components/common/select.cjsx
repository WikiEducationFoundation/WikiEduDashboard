React = require 'react'
Conditional = require '../high_order/conditional'
InputMixin = require '../../mixins/input_mixin'

Select = React.createClass(
  displayName: 'Select'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
  render: ->
    if @props.label
      label = @props.label
      label += @props.spacer || ':'

    options = @props.options.map (option, i) =>
      <option value={i} key={i}>{option}</option>

    if @props.popover_text
      labelClass = 'popover-trigger'
      popover = (
        <div className="popover dark">
          <p>{@props.popover_text}</p>
        </div>
      )

    if @props.editable
      <label className="input_wrapper select_wrapper #{if @props.inline? && @props.inline then ' inline' else ''}">
        <div className={labelClass}>{label}{popover}</div>
        <select
          value={@state.value}
          onChange={@onChange}
        >
          {options}
        </select>
      </label>
    else
      <span>{@props.options[@props.value]}</span>
)

module.exports = Conditional(Select)
