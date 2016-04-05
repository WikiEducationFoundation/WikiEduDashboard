# Used by any component that requires "Edit", "Save", and "Cancel" buttons

React = require 'react'
UIActions = require('../../actions/ui_actions.js').default

Editable = (Component, Stores, Save, GetState, Label) ->
  React.createClass(
    mixins: Stores.map (store) -> store.mixin
    toggleEditable: ->
      @setState editable: !@state.editable
    saveChanges: ->
      UIActions.open null
      Save $.extend(true, {}, @state), @props.course_id
      @toggleEditable()
    cancelChanges: ->
      UIActions.open null
      store.restore() for store in Stores
      @toggleEditable()
    getInitialState: ->
      new_state = GetState()
      new_state.editable = if @state then @state.editable else false
      return new_state
    storeDidChange: ->
      @setState GetState()
    controls: (extra_controls, hide_edit=false, save_only=false) ->
      permissions = @props.current_user.admin || @props.current_user.role > 0

      if permissions && @state.editable
        unless save_only
          className = 'controls'
          cancel = (
            <button onClick={@cancelChanges} className='button'>Cancel</button>
          )

        <div className={className}>
          {cancel}
          <button onClick={@saveChanges} className='dark button'>Save</button>
          {extra_controls}
       </div>
      else if permissions && (@props.editable == undefined || @props.editable)
        edit_label = 'Edit'
        if Label?
          edit_label = Label
        unless hide_edit
          edit = <button onClick={@toggleEditable} className='dark button'>{edit_label}</button>
        <div className="controls">
          {edit}
          {extra_controls}
        </div>
    render: ->
      return <Component {...@props} {...@state} disableSave={@disableSave} controls={@controls} />;
  )

module.exports = Editable
