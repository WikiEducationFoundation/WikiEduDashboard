React           = require 'react'
OverviewStore   = require '../../stores/overview_store'
OverviewActions = require '../../actions/overview_actions'
EditableInterface = require '../common/editable_interface.jsx'

TextInput       = require '../common/text_input'
TextAreaInput   = require '../common/text_area_input'

getState = (course_id) ->
  details: OverviewStore.getDetails(course_id)

Overview = React.createClass(
  displayName: 'Overview'
  updateDetails: (value_key, value) ->
    to_pass = this.props.details
    to_pass[value_key] = value
    OverviewActions.updateDetails to_pass
  render: ->
    <div>
      <p>{this.props.controls}</p>
      <p><span>{this.props.details.title}</span></p>
      <p>
        <TextAreaInput
          onSave={this.updateDetails}
          value={this.props.details.description}
          value_key={'description'}
          editable={this.props.editable}
        />
      </p>
    </div>
)

module.exports = EditableInterface(Overview, OverviewStore, getState, OverviewActions)