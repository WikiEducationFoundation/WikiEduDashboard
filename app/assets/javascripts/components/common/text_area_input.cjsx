React           = require 'react'
md              = require('markdown-it')({ html: true, linkify: true })
InputMixin      = require '../../mixins/input_mixin'
TrixEditor      = require 'react-trix'

TextAreaInput = React.createClass(
  displayName: 'TextAreaInput'

  mixins: [InputMixin]

  propTypes:
    onChange: React.PropTypes.func
    onFocus: React.PropTypes.func
    onBlur: React.PropTypes.func
    value: React.PropTypes.string
    value_key: React.PropTypes.string
    editable: React.PropTypes.bool
    id: React.PropTypes.string
    focus: React.PropTypes.bool
    label: React.PropTypes.string
    placeholder: React.PropTypes.string
    hr: React.PropTypes.bool
    autoExpand: React.PropTypes.bool
    wysiwyg: React.PropTypes.bool

  getInitialState: ->
    value: @props.value

  _handleChange: (e) ->
    @setState value: e.target.innerHTML

  render: ->
    if @props.label
      label = @props.label + ':'
    if @props.wysiwyg
      input_element = (
        <TrixEditor
          value={@state.value}
          onChange={@_handleChange}
        />
      )
    else
      input_element = (
        <textarea
          ref='input'
          id={@props.id || @props.value_key || ''}
          rows={@props.rows || '8'}
          value={@state.html}
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
      else if @props.autoExpand is true
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
      raw_html = md.render(@props.value)
      <div dangerouslySetInnerHTML={{__html: raw_html}}></div>
    else
      <p className="content"></p>
)

module.exports = TextAreaInput
