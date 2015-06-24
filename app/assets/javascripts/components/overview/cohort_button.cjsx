React         = require 'react/addons'
Expandable    = require '../highlevels/expandable'
Popover       = require '../common/popover'
ServerActions = require '../../actions/server_actions'
Conditional   = require '../highlevels/conditional'
CohortStore   = require '../../stores/cohort_store'

CohortButton = React.createClass(
  displayname: 'CohortButton'
  mixins: [CohortStore.mixin]
  storeDidChange: ->
    return unless @refs.cohort_title?
    cohort_title = @refs.cohort_title.getDOMNode().value
    if CohortStore.getFiltered({ title: cohort_title }).length > 0
      alert (cohort_title + ' successfully listed!')
      @refs.cohort_title.getDOMNode().value = ''
      @props.open()
  list: ->
    cohort_title = @refs.cohort_title.getDOMNode().value
    if confirm 'Are you sure you want to add this course to the ' + cohort_title + ' cohort?'
      if CohortStore.getFiltered({ title: cohort_title }).length == 0
        ServerActions.listCourse @props.course_id, cohort_title
      else
        alert 'This course is already listed in that cohort!'
  delist: (cohort_id) ->
    cohort = CohortStore.getFiltered({ id: cohort_id })[0]
    if confirm 'Are you sure you want to remove this course from the ' + cohort.title + ' cohort?'
      ServerActions.delistCourse @props.course_id, cohort.title
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    'cohort_button'
  render: ->
    cohorts = @props.cohorts.map (cohort) =>
      remove_button = (
        <button className='border plus' onClick={@delist.bind(@, cohort.id)}>-</button>
      )
      <tr key={cohort.id + '_cohort'}>
        <td>{cohort.title}{remove_button}</td>
      </tr>

    edit_row = (
      <tr className='edit'>
        <td>
          <input type="text" ref='cohort_title' placeholder='Title' />
          <button className='border' onClick={@list}>List</button>
        </td>
      </tr>
    )

    <div className='pop__container' onClick={@stop}>
      <button className='border plus' onClick={@props.open}>+</button>
      <Popover
        is_open={@props.is_open}
        edit_row={edit_row}
        rows={cohorts}
      />
    </div>
)

module.exports = Conditional(Expandable(CohortButton))
