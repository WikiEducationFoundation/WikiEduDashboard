React             = require 'react'
Week              = require './week'
Editable          = require '../highlevels/editable'
Gradeable         = require './gradeable'

GradeableActions  = require '../../actions/gradeable_actions'
ServerActions     = require '../../actions/server_actions'

BlockStore        = require '../../stores/block_store'
GradeableStore    = require '../../stores/gradeable_store'

getState = ->
  gradeables = []
  from_store = GradeableStore.getGradeables()
  for gradeable in from_store
    gradeables.push(gradeable) unless gradeable.is_new
  gradeables: gradeables

Grading = React.createClass(
  displayName: 'Grading'
  addGradeable: ->
    GradeableActions.addGradeableToCourse
  deleteGradeable: (gradeable_id) ->
    GradeableActions.deleteGradeable gradeable_id
  render: ->
    gradeables = []
    this.props.gradeables.forEach (gradeable, i) =>
      unless gradeable.deleted
        block = BlockStore.getBlock(gradeable.gradeable_item_id)
        block_title = if block? then block.title else gradeable.title
        gradeables.push (
          <Gradeable
            gradeable={gradeable}
            title={block_title}
            key={gradeable.id}
            editable={this.props.editable}
            deleteGradeable={this.deleteGradeable.bind(this, gradeable.id)}
          />
        )
    if this.props.editable
      addGradeable = <li className="row view-all">
        <div>
          <a onClick={this.addGradeable}>Add New Grading Item</a>
        </div>
      </li>

    <div>
      <div className="section-header">
        <h3>Grading</h3>
        {this.props.controls}
      </div>
      <ul className="list">
        {gradeables}
        {addGradeable}
      </ul>
    </div>
)

module.exports = Editable(Grading, [BlockStore, GradeableStore], ServerActions.saveGradeables, getState)