# Used by any component that requires "Edit", "Save", and "Cancel" buttons

React = require 'react'

editable = (Component, Stores, Save, GetState) ->
  React.createClass(
    mixins: Stores.map (store) -> store.mixin
    toggleEditable: ->
      this.setState editable: !this.state.editable
    saveChanges: ->
      Save this.props.course_id, $.extend(true, {}, this.state)
      this.toggleEditable()
    cancelChanges: ->
      store.restore() for store in Stores
      this.toggleEditable()
    getInitialState: ->
      new_state = GetState()
      new_state.editable = if this.state then this.state.editable else false
      return new_state
    storeDidChange: ->
      this.setState GetState()
    render: ->
      if this.state.editable
        controls = (
          <p>
            <button
              value={'cancel'}
              onClick={this.cancelChanges}
            >Cancel</button>
            <button
              value={'save'}
              onClick={this.saveChanges}
            >Save</button>
         </p>
        )
      else
        controls = (
          <p>
            <button
              value={'edit'}
              onClick={this.toggleEditable}
            >Edit</button>
          </p>
        )
      return <Component {...this.props} {...this.state} controls={controls} />;
  )

module.exports = editable
