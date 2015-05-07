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
    gtitle = this.props.gradeable.title
    title = if gtitle.length then gtitle else this.props.title
    <li className="gradeable">
      <TextInput
        onChange={this.updateGradeable}
        value={title}
        value_key={'title'}
        editable={this.props.editable && gtitle.length}
      />
      <TextInput
        onChange={this.updateGradeable}
        value={this.props.gradeable.points}
        value_key={'points'}
        editable={this.props.editable}
      />
    </li>
)

module.exports = Gradeable