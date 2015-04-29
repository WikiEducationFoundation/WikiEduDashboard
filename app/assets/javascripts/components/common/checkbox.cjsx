React = require 'react'
InputMixin = require '../../mixins/input_mixin'

Checkbox = React.createClass(
  displayName: 'Checkbox'
  mixins: [InputMixin],
  onCheckboxChange: (e) ->
    if e.target.checked != this.props.value
      this.setState value: e.target.checked, =>
        this.save()
  render: ->
    <input
      type="checkbox"
      checked={this.state.value}
      onChange={this.onCheckboxChange}
      disabled={!this.props.editable}
    />
)

module.exports = Checkbox
