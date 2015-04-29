React = require 'react'
InputMixin = require '../../mixins/input_mixin'

TextAreaInput = React.createClass(
  displayName: 'TextAreaInput'
  mixins: [InputMixin],
  render: ->
    if this.props.editable
      <textarea
        value={this.state.value}
        onBlur={this.save}
        onChange={this.onChange}
        autoFocus={this.props.focus}
      />
    else if this.state.value
      <span dangerouslySetInnerHTML={{__html: this.state.value.replace(/(?:\r\n|\r|\n)/g, '<br>')}}></span>
    else
      <span></span>
)

module.exports = TextAreaInput
