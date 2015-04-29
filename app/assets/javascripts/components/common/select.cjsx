React = require 'react'
InputMixin = require '../../mixins/input_mixin'

Select = React.createClass(
  displayName: 'Select'
  mixins: [InputMixin],
  onSelectChange: (e) ->
    if e.target.value != this.state.value
      this.setState value: e.target.value, =>
        this.save()
  render: ->
    options = this.props.options.map (option, i) =>
      <option value={i}>{option}</option>

    if this.props.editable
      <select
        value={this.state.value}
        onChange={this.onSelectChange}
      >
        {options}
      </select>
    else
      <span>{this.props.options[this.state.value]}</span>
)

module.exports = Select
