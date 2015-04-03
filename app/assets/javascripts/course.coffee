$ ->
  # Course sorting
  courseList = new List('courses', {valueNames: ['title','characters','views','students']})

  # User sorting
  userList = new List('users', {valueNames: ['name','training','characters-ms', 'characters-us', 'edits']})

  # Article sorting
  articleList = new List('articles', {valueNames: ['rating_num', 'title','characters','views']})

  # Revision sorting
  revisionList = new List('revisions', {valueNames: ['title', 'date', 'characters', 'views']})

  $('select.cohorts').change (e) ->
    cohort = $('select.cohorts option:selected').val()
    window.location = "/courses?cohort=" + encodeURIComponent(cohort)

  $('select.sorts').change (e) ->
    list = switch($(this).attr('rel'))
      when "courses" then courseList
      when "users" then userList
      when "articles" then articleList
      when "revisions" then revisionList
    list.sort($(this).val(), { order: $(this).children('option:selected').attr('rel') })

  $('a.manual_update').click (e) ->
    e.preventDefault()
    console.log 'Updating course...'
    $(e.target).parent().text('Updating course data. This page will reload when new data is available.')
    $.get($(e.target).attr('href'), (data) ->
      location.reload()
    )

  $('a.notify_untrained').click (e) ->
    e.preventDefault()
    parent = $(e.target).parent()
    if confirm "This will post a reminder on the talk pages for all students who have not completed training. Are you sure?"
      console.log 'Notifying untrained users...'
      parent.text('Posting a reminder to the talk page of all untrained students. Please wait...')
      $.get($(e.target).attr('href'), (data) =>
        alert("Untrained users have been notified!")
        parent.text('Untrained students have been reminded to complete the training!')
      )

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