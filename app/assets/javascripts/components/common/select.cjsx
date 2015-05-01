React = require 'react'
InputMixin = require '../../mixins/input_mixin'

Select = React.createClass(
  displayName: 'Select'
  mixins: [InputMixin],
  getInitialState: ->
    value: this.props.value
  render: ->
    options = this.props.options.map (option, i) =>
      <option value={i} key={i}>{option}</option>

    if this.props.editable
      <select
        value={this.state.value}
        onChange={this.onChange}
      >
        {options}
      </select>
    else
      <span>{this.props.options[this.props.value]}</span>
)

module.exports = Select
