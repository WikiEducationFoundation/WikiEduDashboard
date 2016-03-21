React           = require 'react'
md              = require('markdown-it')({ html: true, linkify: true })
InputMixin      = require '../../mixins/input_mixin.cjsx'
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
    markdown: React.PropTypes.bool

  getInitialState: ->
    value: @props.value

  _handleChange: (e) ->
    @onChange(e)
    @setState value: e.target.innerHTML

  render: ->
    if @props.label
      label = @props.label + ':'

    if @props.editable
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
            value={@state.value}
            onChange={@onChange}
            autoFocus={@props.focus}
            onFocus={@focus}
            onBlur={@blur}
            placeholder={@props.label || @props.placeholder}
          />
        )

      if @props.autoExpand
        wrapped = (
          <div className="expandingArea active">
            <pre><span>{@state.value}</span><br/></pre>
            {input_element}
          </div>
        )
      else
        wrapped = input_element

      if @props.hr
        hr = <hr/>

      if @props.label
        return (
          <label>
            {hr}
            {wrapped}
          </label>
        )
      else
        return (
          <div>
            {hr}
            {wrapped}
          </div>
        )
    else
      if @props.markdown
        raw_html = md.render(@props.value || '')
      else
        raw_html = @props.value
      return (
        <div className={@props.className} dangerouslySetInnerHTML={{__html: raw_html}}></div>
      )
)

module.exports = TextAreaInput
