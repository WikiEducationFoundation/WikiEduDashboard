React         = require 'react/addons'
Typeahead     = require('react-typeahead').Typeahead
LookupStore   = require '../../stores/lookup_store'
TextInput     = require './text_input'

getState = (model) ->
  models: LookupStore.getLookups(model)
  submitting: false

Lookup = React.createClass(
  displayname: 'Lookup'
  mixins: [LookupStore.mixin]
  getInitialState: ->
    getState(@props.model)
  storeDidChange: ->
    @setState getState(@props.model)
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
        options={@state.models}
        placeholder={@props.placeholder || 'Start typing'}
        maxVisible=5
        ref='entry'
        onKeyDown={@keyDownHandler}
        onOptionSelected={@optionSelectedHandler}
      />
    else
      <input placeholder={@props.placeholder || 'Start typing'} ref='entry' />
)

module.exports = Lookup
