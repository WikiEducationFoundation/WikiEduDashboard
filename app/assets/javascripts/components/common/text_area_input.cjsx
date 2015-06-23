React           = require 'react'
Marked          = require 'marked'
MarkedRenderer  = require '../../utils/marked_renderer'
InputMixin      = require '../../mixins/input_mixin'

TextAreaInput = React.createClass(
  displayName: 'TextAreaInput'
  mixins: [InputMixin],
  getInitialState: ->
    value: @props.value
  render: ->
    if @props.label
      label = @props.label + ':'
    input_element = (
      <textarea
        ref='input'
        id={@props.id || @props.value_key || ''}
        rows={@props.rows || '8'}
        value={@state.value}
        onChange={@onChange}
        autoFocus={@props.focus}
        onFocus={@focus}
        onBlur={@blur}
        placeholder={@props.label || @props.placeholder}
      />
    )
    if @props.editable
      if @props.hr and @props.autoExpand is false
        <label><hr />{label}
          {input_element}
        </label>
      else if @props.hr and @props.autoExpand is true
        <label><hr />{label}
          <div className="expandingArea active">
            <pre><span>{@state.value}</span><br/></pre>
            {input_element}
          </div>
        </label>
      else
        if @props.autoExpand is true
          <label>{label}
            <div className="expandingArea active">
              <pre><span>{@state.value}</span><br/></pre>
              {input_element}
            </div>
          </label>
        else
          <label>{label}
            {input_element}
          </label>
    else if @props.value
      raw_html = Marked(@props.value, { renderer: MarkedRenderer })
      <div dangerouslySetInnerHTML={{__html: raw_html}}></div>
    else
      <p className="content"></p>
)

module.exports = TextAreaInput
