React             = require 'react'
Gradeable         = require './gradeable'
GradeableActions  = require '../../actions/gradeable_actions'
BlockStore        = require '../../stores/block_store'

Grading = React.createClass(
  displayName: 'Grading'
  addGradeable: ->
    GradeableActions.addGradeableToCourse()
  deleteGradeable: (gradeable_id) ->
    GradeableActions.deleteGradeable gradeable_id
  render: ->
    total = _.sum(@props.gradeables, 'points')
    gradeables = @props.gradeables.map (gradeable, i) =>
      unless gradeable.deleted
        block = BlockStore.getBlock(gradeable.gradeable_item_id)
        <Gradeable
          gradeable={gradeable}
          block={block}
          key={gradeable.id}
          editable={@props.editable}
          total={total}
          deleteGradeable={@deleteGradeable.bind(this, gradeable.id)}
        />
    gradeables.sort (a, b) ->
      return 1 unless a.props.gradeable? && b.props.gradeable?
      a.props.gradeable.order - b.props.gradeable.order
    if @props.editable && false
      addGradeable = (
        <li className="row view-all">
          <div>
            <button className='button dark' onClick={@addGradeable}>Add New Grading Item</button>
          </div>
        </li>
      )
    unless gradeables.length
      no_gradeables = (
        <li className="row view-all">
          <div><p>This course has no gradeable assignments</p></div>
        </li>
      )

    <div>
      <div className="section-header">
        <h3>Grading <span>(Total: {total}%)</span></h3>
        {@props.controls(null, @props.gradeables.length < 1)}
      </div>
      <ul className="list-unstyled">
        {gradeables}
        {no_gradeables}
        {addGradeable}
      </ul>
    </div>
)

module.exports = Grading
