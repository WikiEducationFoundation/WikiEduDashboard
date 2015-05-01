React = require 'react'
InputMixin = require '../../mixins/input_mixin'

Checkbox = React.createClass(
  displayName: 'Checkbox'
  mixins: [InputMixin],
  getInitialState: ->
    value: this.props.value
  onCheckboxChange: (e) ->
    e.target.value = e.target.checked
    this.onChange e
  render: ->
    <input
      type="checkbox"
      checked={this.state.value}
      onChange={this.onCheckboxChange}
      disabled={!this.props.editable}
    />
)

module.exports = Checkbox
