React = require 'react'
LookupWrapper = require '../high_order/lookup_wrapper.cjsx'

LookupSelect = React.createClass(
  displayName: 'LookupSelect'
  getValue: ->
    @refs.entry.getDOMNode().value
  clear: ->
    @refs.entry.getDOMNode().value = 'placeholder'
  render: ->
    options = @props.models.map (model, i) =>
      <option value={model} key={model}>{model}</option>

    <div className='select_wrapper'>
      <select name={@props.placeholder.toLowerCase()} ref='entry' defaultValue='placeholder'>
        <option value='placeholder' key='placeholder' disabled=true>{"Select a #{@props.placeholder}" || 'Select one'}</option>
        {options}
      </select>
    </div>
)

module.exports = LookupWrapper(LookupSelect)
