React             = require 'react'
TextInput         = require '../common/text_input.cjsx'
GradeableActions  = require('../../actions/gradeable_actions.js').default

Gradeable = React.createClass(
  displayName: 'Gradeable'
  updateGradeable: (value_key, value) ->
    to_pass = $.extend(true, {}, @props.gradeable)
    to_pass[value_key] = value
    GradeableActions.updateGradeable to_pass
  render: ->
    block = @props.block
    title = if block? then block.title else @props.gradeable.title

    unless @props.editable
      percent_num = ((@props.gradeable.points / @props.total) * 100).toFixed(1)
      percent = <span> ({percent_num}%)</span>

    <li className="gradeable block">
      <h4 className={"block-title" + (if @props.editable then " block-title--editing" else "")}>
        <TextInput
          onChange={@updateGradeable}
          value={title}
          value_key={'title'}
          editable={@props.editable && @props.gradeable.title.length}
        />
      </h4>
      <TextInput
        onChange={@updateGradeable}
        value={@props.gradeable.points}
        value_key={'points'}
        editable={@props.editable}
        label={I18n.t('timeline.gradeable_value')}
        append='%'
      />
    </li>
)

module.exports = Gradeable
