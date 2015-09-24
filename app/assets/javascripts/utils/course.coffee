$ ->
  # Course sorting
  # only sort if there are uls to sort
  if $('section#courses ul').length
    adminCourseList = new List('admin_courses', {
      valueNames: ['atitle']
    })
    userCourseList = new List('user_courses', {
      valueNames: ['utitle','ucharacters','uviews','ustudents']
    })
    courseList = new List('courses', {
      valueNames: ['title','revisions','characters','views','students']
    })

  $('select.cohorts').change (e) ->
    cohort = $('select.cohorts option:selected').val()
    window.location = "/courses?cohort=" + encodeURIComponent(cohort)

  $('select.sorts').change (e) ->
    list = switch($(this).attr('rel'))
      when "courses" then courseList
    if list?
      list.sort($(this).val(), {
        order: $(this).children('option:selected').attr('rel')
      })

  $('a.manual_update').click (e) ->
    e.preventDefault()
    $(e.target).parent().text("""
      Updating course data. This page will reload when new data is available.
    """)
    $.get($(e.target).attr('href'), (data) ->
      location.reload()
    )

  $('.notify_untrained').click (e) ->
    e.preventDefault()
    if confirm 'This will post a reminder on the talk pages for all
      students who have not completed training. Are you sure you want
      to do this?'
      $(e.target).addClass('loading')
      $.get($(e.target).attr('href'), (data) ->
        $(e.target).removeClass('loading')
        alert "Untrained users have been reminded to complete the training."
      )
