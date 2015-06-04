$ ->
  # Course sorting
  userCourseList = new List('user_courses', {
    valueNames: ['utitle','ucharacters','uviews','ustudents']
  })
  courseList = new List('courses', {
    valueNames: ['title','characters','views','students']
  })

  # Activity sorting
  activityList = new List('activity', {
    valueNames: ['rating_num', 'title', 'edited_by', 'characters', 'date_time']
  })

  # # User sorting
  # userList = new List('users', {
  #   valueNames: ['name','training','characters-ms', 'characters-us', 'assignee', 'reviewer']
  # })

  # Article sorting
  articleList = new List('articles', {
    valueNames: ['rating_num', 'title', 'assigned_to', 'characters', 'views']
  })

  # Revision sorting
  revisionList = new List('revisions', {
    valueNames: ['title', 'date', 'characters', 'views']
  })

  $('select.cohorts').change (e) ->
    cohort = $('select.cohorts option:selected').val()
    window.location = "/courses?cohort=" + encodeURIComponent(cohort)

  $('select.sorts').change (e) ->
    list = switch($(this).attr('rel'))
      when "courses" then courseList
      when "activity" then activityList
      when "users" then userList
      when "articles" then articleList
      when "revisions" then revisionList
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

  $('.button.assign').click (e) ->
    course_id = $(this).data('course_id')
    user_id = $(this).data('user_id')
    article_title = prompt("Enter the article title to assign.")
    $.ajax
      type: 'POST'
      url: '/courses/' + course_id + '/students/assign'
      contentType: 'application/json'
      data: JSON.stringify(
        assignment:
          user_id: user_id,
          article_title: article_title
      )
      success: (data) ->
        window.location.reload()

  $('.button.review').click (e) ->
    course_id = $(this).data('course_id')
    assignment_id = $(this).data('assignment_id')
    reviewer_wiki_id = prompt("Enter the Wiki id of the user to add as a reviewer.")
    $.ajax
      type: 'POST'
      url: '/courses/' + course_id + '/students/review'
      contentType: 'application/json'
      data: JSON.stringify(
        assignment_id: assignment_id,
        reviewer_wiki_id: reviewer_wiki_id
      )
      success: (data) ->
        window.location.reload()

  $('#react_root').on 'click', '.wizard__option__more', (e) ->
    $(this).prev().find('.wizard__option__description').toggleHeight()

$.fn.extend
  toggleHeight: ->
    return @each ->
      height = '0px'
      if $(@).css('height') == undefined || $(@).css('height') == '0px'
        height = $(@).getContentHeight()
      $(@).css('height', height)

  getContentHeight: ->
    elem = $(@).clone().css(
      "height":"auto"
      "display":"block"
    ).appendTo($(@).parent())
    height = elem.css("height")
    elem.remove()
    return height