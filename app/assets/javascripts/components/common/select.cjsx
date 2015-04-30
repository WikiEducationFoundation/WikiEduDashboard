React = require 'react'
InputMixin = require '../../mixins/input_mixin'

Select = React.createClass(
  displayName: 'Select'
  mixins: [InputMixin],
  onSelectChange: (e) ->
    this.onChange e
  render: ->
    options = this.props.options.map (option, i) =>
      <option value={i}>{option}</option>

    if this.props.editable
      <select
        value={this.props.value}
        onChange={this.onSelectChange}
      >
        {options}
      </select>
    else
      <span>{this.props.options[this.props.value]}</span>
)

module.exports = Select
