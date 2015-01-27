$ ->
  # Course sorting
  courseList = new List('courses', {valueNames: ['title','characters','views','students']})

  # User sorting
  userList = new List('users', {valueNames: ['name','training','characters-ms', 'characters-us', 'edits']})

  # Article sorting
  articleList = new List('articles', {valueNames: ['title','characters','views']})

  # Revision sorting
  revisionList = new List('revisions', {valueNames: ['title', 'date', 'characters', 'views']})

  # User detail display
  $('.drawer_trigger').click (e) ->
    drawer = $(e.target).parents('.row').children('.drawer')

    $('.drawer').not(drawer).css('height', '0px')
    $('.row.open').not($(e.target).parents('.row')).removeClass('open')

    drawer.toggleHeight()
    $(e.target).parents('.row').toggleClass('open')

  $('select.cohorts').change (e) ->
    cohort = $('select.cohorts option:selected').val()
    window.location = "/courses?cohort=" + encodeURIComponent(cohort)

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