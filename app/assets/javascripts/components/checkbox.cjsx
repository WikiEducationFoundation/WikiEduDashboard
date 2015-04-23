React = require 'react'
InputMixin = require '../mixins/input_mixin'

Checkbox = React.createClass(
  mixins: [InputMixin],
  onCheckboxChange: (e) ->
    if e.target.checked != this.props.value
      this.setState value: e.target.checked, =>
        this.save()
  render: ->
    if this.props.editable || false
      <input
        type="checkbox"
        checked={this.state.value}
        onChange={this.onCheckboxChange}
      />
    else
      <p>{this.state.value}</p>
)

module.exports = Checkbox
