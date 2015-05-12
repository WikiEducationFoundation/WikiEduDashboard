# Used by any component that requires "Edit", "Save", and "Cancel" buttons

React = require 'react'

editable = (Component, Stores, Save, GetState) ->
  React.createClass(
    mixins: Stores.map (store) -> store.mixin
    toggleEditable: ->
      this.setState editable: !this.state.editable
    saveChanges: ->
      Save $.extend(true, {}, this.state), this.props.course_id
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
      if this.props.permit && this.state.editable
        controls = (
          <div className="controls">
            <div
              className='button large'
              value={'cancel'}
              onClick={this.cancelChanges}
            >Cancel</div>
            <div
              className='button dark large'
              value={'save'}
              onClick={this.saveChanges}
            >Save</div>
         </div>
        )
      else if this.props.permit && (this.props.editable == undefined || this.props.editable)
        controls = (
          <div className="controls">
            <div
              className='button dark large'
              value={'edit'}
              onClick={this.toggleEditable}
            >Edit</div>
          </div>
        )
      return <Component {...this.props} {...this.state} controls={controls} />;
  )

module.exports = editable
