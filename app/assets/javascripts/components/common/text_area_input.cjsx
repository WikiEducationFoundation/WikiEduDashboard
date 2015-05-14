React = require 'react'
InputMixin = require '../../mixins/input_mixin'

TextAreaInput = React.createClass(
  displayName: 'TextAreaInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
  render: ->
    if @props.editable
      if @props.hr
        <div>
          <hr />
          <textarea
            value={@state.value}
            onChange={@onChange}
            autoFocus={@props.focus}
            placeholder={@props.placeholder}
          />
        </div>
      else
        <p className="content">
          <textarea
            value={@state.value}
            onChange={@onChange}
            autoFocus={@props.focus}
            placeholder={@props.placeholder}
          />
        </p>
    else if @props.value
      inner_html = @props.value.replace(/(?:\r\n|\r|\n)/g, '<br>')
      <p className="content"><span dangerouslySetInnerHTML={{__html: inner_html}}></span></p>
    else
      <p className="content"></p>
)

module.exports = TextAreaInput
