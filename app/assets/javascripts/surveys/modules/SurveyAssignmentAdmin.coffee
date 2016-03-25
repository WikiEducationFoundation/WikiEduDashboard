SurveyAssignmentAdmin =
  init: ->
    @sortableTables()

  sortableTables: ->
    $('[data-sortable-courses]').each (i, sortable_courses) ->
      $table = $(sortable_courses)
      options =
        valueNames: [ 'title', 'id' ]

      new List sortable_courses, options

module.exports = SurveyAssignmentAdmin