React     = require 'react/addons'
UIActions = require '../../actions/ui_actions'
UIStore   = require '../../stores/ui_store'

ExpandableTrigger = (Component, Key) ->
  React.createClass(
    mixins: [UIStore.mixin]
    displayName: 'ExpandableTrigger'
    storeDidChange: ->
      @setState is_open: UIStore.getOpenKey() == Key
    getInitialState: ->
      is_open: false
    stop: (e) ->
      console.log("stop")
      e.stopPropagation()
    render: ->
      <Component {...@state} {...@props} @stop={@stop} />
  )

module.exports = ExpandableTrigger
