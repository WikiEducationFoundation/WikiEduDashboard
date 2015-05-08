React             = require 'react/addons'
TextInput         = require '../common/text_input'
GradeableActions  = require '../../actions/gradeable_actions'

Gradeable = React.createClass(
  displayName: 'Gradeable'
  updateGradeable: (value_key, value) ->
    to_pass = $.extend({}, this.props.gradeable)
    to_pass[value_key] = value
    GradeableActions.updateGradeable to_pass
  render: ->
    block = @props.block
    title = if block? then block.title else @props.gradeable.title
    <li className="gradeable block">
      <h4>
        <TextInput
          onChange={this.updateGradeable}
          value={title}
          value_key={'title'}
          editable={this.props.editable && @props.gradeable.title.length}
        />
      </h4>
      <p><span>Points: </span>
        <TextInput
          onChange={this.updateGradeable}
          value={this.props.gradeable.points}
          value_key={'points'}
          editable={this.props.editable}
        />
      </p>
    </li>
)

module.exports = Gradeable