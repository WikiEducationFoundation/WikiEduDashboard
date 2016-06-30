React = require 'react'
Conditional = require('../high_order/conditional.jsx').default
InputMixin = require '../../mixins/input_mixin.cjsx'

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

    if @props.tooltip_text
      labelClass = 'tooltip-trigger'
      tooltip = (
        <div className="tooltip dark">
          <p>{@props.tooltip_text}</p>
        </div>
      )

    if @props.editable
      <div className="form-group">
        <label htmlFor={@state.id} className={labelClass}>{label}{tooltip}</label>
        <select
          id={@state.id}
          value={@state.value}
          onChange={@onChange}
        >
          {options}
        </select>
      </div>
    else
      <span>{@props.options[@props.value]}</span>
)

module.exports = Conditional(Select)
