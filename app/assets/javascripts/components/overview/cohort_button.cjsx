React         = require 'react'
PopoverButton = require '../high_order/popover_button.cjsx'
CohortStore   = require '../../stores/cohort_store.coffee'

cohortIsNew = (cohort) ->
  CohortStore.getFiltered({ title: cohort }).length == 0

cohorts = (props, remove) ->
  props.cohorts.map (cohort) =>
    remove_button = (
      <button className='button border plus' onClick={remove.bind(null, cohort.id)}>-</button>
    )
    <tr key={cohort.id + '_cohort'}>
      <td>{cohort.title}{remove_button}</td>
    </tr>

module.exports = PopoverButton('cohort', 'title', CohortStore, cohortIsNew, cohorts, true)
