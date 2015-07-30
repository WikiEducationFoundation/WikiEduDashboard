React = require 'react'
LookupWrapper = require '../high_order/lookup_wrapper'

LookupSelect = React.createClass(
  displayName: 'LookupSelect'
  getValue: ->
    @refs.entry.getDOMNode().value
  clear: ->
    console.log 'select the first option??'
  keyDownHandler: (e) ->
    if e.keyCode == 13 && @getValue() != ''
      @props.onSubmit e
  render: ->
    options = @props.models.map (model, i) =>
      <option value={model} key={model}>{model}</option>

    <select
      onKeyDown={@keyDownHandler}
    >
      {options}
    </select>
)

module.exports = LookupWrapper(LookupSelect)
