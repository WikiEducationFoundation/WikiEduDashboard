React = require 'react'
InputMixin = require '../../mixins/input_mixin'
Conditional = require '../highlevels/conditional'

TextInput = React.createClass(
  displayName: 'TextInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: this.props.value
  render: ->
    value = this.props.value
    if this.props.type == 'date'
      v_date = new Date(value)
      value = v_date.getMonth() + '/' + v_date.getDate() + '/' + v_date.getFullYear()
    if this.props.editable
      <input
        value={this.state.value}
        onChange={this.onChange}
        autoFocus={this.props.focus}
        type={this.props.type || 'text'}
      />
    else
      <span>{value}</span>
)

module.exports = Conditional(TextInput)
