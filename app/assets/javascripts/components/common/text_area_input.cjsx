React = require 'react'
InputMixin = require '../../mixins/input_mixin'

TextAreaInput = React.createClass(
  displayName: 'TextAreaInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
  render: ->
    if @props.label
      label = @props.label + ':'
    if @props.editable
      if @props.hr
        <label><hr />{label}
          <textarea
            rows='8'
            value={@state.value}
            onChange={@onChange}
            autoFocus={@props.focus}
            placeholder={@props.label}
          />
        </label>
      else
        <label>{label}
          <textarea
            rows='8'
            value={@state.value}
            onChange={@onChange}
            autoFocus={@props.focus}
            placeholder={@props.label}
          />
        </label>
    else if @props.value
      inner_html = @props.value.replace(/(?:\r\n|\r|\n)/g, '<br>')
      <p className="content"><span dangerouslySetInnerHTML={{__html: inner_html}}></span></p>
    else
      <p className="content"></p>
)

module.exports = TextAreaInput
