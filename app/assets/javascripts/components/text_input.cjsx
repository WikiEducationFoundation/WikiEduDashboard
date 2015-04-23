React = require 'react'
InputMixin = require '../mixins/input_mixin'

TextInput = React.createClass(
  displayName: 'TextInput'
  mixins: [InputMixin],
  render: ->
    if this.props.editable || false
      <input
        value={this.state.value}
        onBlur={this.save}
        onChange={this.onChange}
        autoFocus={this.props.focus || false}
      />
    else
      <p>{this.state.value}</p>
)

module.exports = TextInput
