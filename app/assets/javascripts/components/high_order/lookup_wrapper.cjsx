React         = require 'react/addons'
LookupStore   = require '../../stores/lookup_store'

LookupWrapper = (Component, Model) ->
  getState = (model) ->
    models: LookupStore.getLookups(model)
    submitting: false
  React.createClass(
    displayname: 'LookupWrapper'
    mixins: [LookupStore.mixin]
    getInitialState: ->
      getState(@props.model)
    storeDidChange: ->
      @setState getState(@props.model)
    getValue: ->
      @refs.entry.getValue()
    clear: ->
      @refs.entry.clear()
    render: ->
      <Component {...@props} {...@state} ref='entry' />
  )

module.exports = LookupWrapper
