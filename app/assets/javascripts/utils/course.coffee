$ ->
  # Find tables with rows with data-link attribute, then make them clickable
  $('tr[data-link]').on 'click', (e) ->
    loc = $(this).attr('data-link')
    if e.metaKey || (window.navigator.platform.toLowerCase().indexOf('win') != -1 && e.ctrlKey)
      window.open(loc, '_blank')
    else
      window.location = loc
    return false

  # Course sorting
  # only sort if there are tables to sort
  if $('#user_courses table').length
    userCourseList = new List('user_courses', {
      page: 500,
      valueNames: [
        'utitle','urevisions','ucharacters','uaverage-words','uviews','ustudents','ucreation-date','uuntrained'
      ]
    })

  if $('#courses table').length
    courseList = new List('courses', {
      page: 500,
      valueNames: [
        'title','revisions','characters','average-words','views','students','creation-date','untrained'
      ]
    })

  $('select.cohorts').change (e) ->
    cohort = $('select.cohorts option:selected').val()
    window.location = "/explore?cohort=" + encodeURIComponent(cohort)

  $('select.sorts').change (e) ->
    list = switch($(this).attr('rel'))
      when "courses" then courseList
    if list?
      list.sort($(this).val(), {
        order: $(this).children('option:selected').attr('rel')
      })
