React         = require 'react/addons'
Typeahead     = require('react-typeahead').Typeahead
LookupStore   = require '../../stores/lookup_store'
TextInput     = require './text_input'
LookupWrapper = require '../high_order/lookup_wrapper'

Lookup = React.createClass(
  displayname: 'Lookup'
  getValue: ->
    if !(@props.disabled? && @props.disabled)
      @refs.entry.state.entryValue
    else
      @refs.entry.getDOMNode().value
  clear: ->
    if !(@props.disabled? && @props.disabled)
      @refs.entry.setState entryValue: ''
    else
      @refs.entry.getDOMNode().value = ''
  optionSelectedHandler: (option, e) ->
    @keyDownHandler(e)
  keyDownHandler: (e) ->
    made_selection = @refs.entry.getSelection()?
    selection_matches = @refs.entry.getSelection() == @getValue()
    if e.keyCode == 13 && @getValue() != '' && (selection_matches || !made_selection)
      @props.onSubmit e
  render: ->
    if !(@props.disabled? && @props.disabled)
      <Typeahead
        options={@props.models}
        placeholder={@props.placeholder || 'Start typing'}
        maxVisible=5
        ref='entry'
        onKeyDown={@keyDownHandler}
        onOptionSelected={@optionSelectedHandler}
      />
    else
      <input placeholder={@props.placeholder || 'Start typing'} ref='entry' />
)

module.exports = LookupWrapper(Lookup)
