SurveyAssignmentAdmin =
  init: ->
    @sortableTables()
    @listeners()

  listeners: ->
    $('[data-toggle-courses-table]').on 'click', $.proxy @, 'toggleCoursesTable'

  sortableTables: ->
    $('[data-sortable-courses]').each (i, sortable_courses) ->
      $table = $(sortable_courses)
      options =
        valueNames: [ 'title', 'id' ]

      new List sortable_courses, options

  toggleCoursesTable: ({target}) ->
    console.log target
    $(target).parents('.block').find('[data-sortable-courses]').toggleClass 'active'

module.exports = SurveyAssignmentAdmin