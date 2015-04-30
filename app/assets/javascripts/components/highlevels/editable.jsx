// Written in JSX as an exercise, may convert to CJSX later
// Used by any component that requires "Edit", "Save", and "Cancel" buttons

React = require('react');

function editable(Component, Store, Actions, GetState) {
  var Editable = React.createClass({
    mixins: [Store.mixin],
    toggleEditable: function() {
      this.setState({
        editable: !this.state.editable
      });
    },
    saveChanges: function() {
      Actions.save();
      this.toggleEditable();
    },
    cancelChanges: function() {
      Store.restore();
      this.toggleEditable();
    },
    getInitialState: function() {
      var new_state = GetState();
      new_state.editable = this.state ? this.state.editable : false;
      return new_state;
    },
    storeDidChange: function() {
      this.setState(GetState());
    },
    render: function() {
      var controls;
      if(this.state.editable) {
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
        );
      } else {
        controls = (
          <p>
            <button
              value={'edit'}
              onClick={this.toggleEditable}
            >Edit</button>
          </p>
        );
      }
      return <Component {...this.props} {...this.state} controls={controls} />;
    }
  });

  return Editable;
}

module.exports = editable;
