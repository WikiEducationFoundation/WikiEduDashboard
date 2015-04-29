// Written in JSX as an exercise, may convert to CJSX later

React = require('react');

function editableInterface(Component, Store, GetState, Actions) {
  var EditableInterface = React.createClass({
    contextTypes: {
      router: React.PropTypes.func.isRequired
    },
    mixins: [Store.mixin],
    getCourseID: function() {
      var params = this.context.router.getCurrentParams();
      return params.course_school + '/' + params.course_title;
    },
    toggleEditable: function() {
      this.setState({
        editable: !this.state.editable
      });
    },
    saveChanges: function() {
      Actions.save(this.getCourseID());
      this.toggleEditable();
    },
    cancelChanges: function() {
      Actions.get(this.getCourseID());
      this.toggleEditable();
    },
    getInitialState: function() {
      var new_state = GetState(this.getCourseID());
      new_state.editable = this.state ? this.state.editable : false;
      return new_state;
    },
    storeDidChange: function() {
      this.setState(GetState(this.getCourseID()));
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

  return EditableInterface;
}

module.exports = editableInterface;
