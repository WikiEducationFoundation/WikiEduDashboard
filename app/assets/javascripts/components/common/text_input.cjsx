React = require 'react'
InputMixin = require '../../mixins/input_mixin'

TextInput = React.createClass(
  displayName: 'TextInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: this.props.value
  render: ->
    if this.props.editable
      <input
        value={this.state.value}
        onChange={this.onChange}
        autoFocus={this.props.focus}
      />
    else
      <span>{this.props.value}</span>
)

module.exports = TextInput
