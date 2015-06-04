# Used by any component that requires "Edit", "Save", and "Cancel" buttons

React = require 'react'

Editable = (Component, Stores, Save, GetState) ->
  React.createClass(
    mixins: Stores.map (store) -> store.mixin
    toggleEditable: ->
      @setState editable: !@state.editable
    saveChanges: ->
      Save $.extend(true, {}, @state), @props.course_id
      @toggleEditable()
    cancelChanges: ->
      store.restore() for store in Stores
      @toggleEditable()
    getInitialState: ->
      new_state = GetState()
      new_state.editable = if @state then @state.editable else false
      return new_state
    storeDidChange: ->
      @setState GetState()
    controls: (extra_controls) ->
      button_size_class = if @props.large_button then ' large' else ''
      button_class = 'button' + button_size_class
      button_dark_class = 'button dark' + button_size_class
      permissions = @props.current_user.admin || @props.current_user.role > 0
      if permissions && @state.editable
        <div className="controls">
          <div
            className={button_class}
            value={'cancel'}
            onClick={@cancelChanges}
          >Cancel</div>
          <div
            className={button_dark_class}
            value={'save'}
            onClick={@saveChanges}
          >Save</div>
          {extra_controls}
       </div>
      else if permissions && (@props.editable == undefined || @props.editable)
        <div className="controls">
          <div
            className={button_dark_class}
            value={'edit'}
            onClick={@toggleEditable}
          >Edit</div>
          {extra_controls}
        </div>
    render: ->
      return <Component {...@props} {...@state} controls={@controls} />;
  )

module.exports = Editable
