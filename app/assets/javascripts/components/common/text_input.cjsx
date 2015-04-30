React = require 'react'
InputMixin = require '../../mixins/input_mixin'

TextInput = React.createClass(
  displayName: 'TextInput'
  mixins: [InputMixin],
  render: ->
    if this.props.editable
      <input
        value={this.props.value}
        onBlur={this.save}
        onChange={this.onChange}
        autoFocus={this.props.focus}
      />
    else
      <span>{this.props.value}</span>
)

module.exports = TextInput
