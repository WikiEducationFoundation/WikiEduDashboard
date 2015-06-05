React     = require 'react/addons'
UIActions = require '../../actions/ui_actions'
UIStore   = require '../../stores/ui_store'

Expandable = (Component) ->
  React.createClass(
    mixins: [UIStore.mixin]
    displayName: 'Expandable'
    storeDidChange: ->
      @setState is_open: UIStore.getOpenKey() == @refs.component.getKey()
    getInitialState: ->
      is_open: false
    open: (e) ->
      e.stopPropagation() if e?
      UIActions.open @refs.component.getKey()
    stop: (e) ->
      e.stopPropagation()
    render: ->
      <Component {...@state} {...@props} open={@open} stop={@stop} ref={'component'} />
  )

module.exports = Expandable
