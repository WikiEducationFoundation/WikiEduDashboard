React = require 'react'
InputMixin = require '../../mixins/input_mixin'

TextAreaInput = React.createClass(
  displayName: 'TextAreaInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: this.props.value
  render: ->
    if this.props.editable
      if this.props.hr
        <div>
          <hr />
          <textarea
            value={this.state.value}
            onChange={this.onChange}
            autoFocus={this.props.focus}
            placeholder={this.props.placeholder}
          />
        </div>
      else
        <p className="content">
          <textarea
            value={this.state.value}
            onChange={this.onChange}
            autoFocus={this.props.focus}
            placeholder={this.props.placeholder}
          />
        </p>
    else if this.props.value
      inner_html = this.props.value.replace(/(?:\r\n|\r|\n)/g, '<br>')
      <p className="content" dangerouslySetInnerHTML={{__html: inner_html}}></p>
    else
      <p className="content"></p>
)

module.exports = TextAreaInput
