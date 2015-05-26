React       = require 'react'
Marked      = require 'marked'
InputMixin  = require '../../mixins/input_mixin'

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
            rows={@props.rows || '8'}
            value={@state.value}
            onChange={@onChange}
            autoFocus={@props.focus}
            placeholder={@props.label || @props.placeholder}
          />
        </label>
      else
        <label>{label}
          <textarea
            rows={@props.rows || '8'}
            value={@state.value}
            onChange={@onChange}
            autoFocus={@props.focus}
            placeholder={@props.label || @props.placeholder}
          />
        </label>
    else if @props.value
      <div dangerouslySetInnerHTML={{__html: Marked(@props.value)}}></div>
    else
      <p className="content"></p>
)

module.exports = TextAreaInput
