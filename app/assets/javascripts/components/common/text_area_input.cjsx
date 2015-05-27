React       = require 'react'
Marked      = require 'marked'
InputMixin  = require '../../mixins/input_mixin'

# Set up a custom markdown renderer so links open in a new window
Renderer    = new Marked.Renderer()
Renderer.link = (href, title, text) ->
  '<a href="' + href + '" title="' + title + '" target="_blank">' + text + '</a>'

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
      raw_html = Marked(@props.value, { renderer: Renderer })
      <div dangerouslySetInnerHTML={{__html: raw_html}}></div>
    else
      <p className="content"></p>
)

module.exports = TextAreaInput
