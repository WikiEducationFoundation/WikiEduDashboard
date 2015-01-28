$ ->
  $('.drawer .view-all a').click (e) ->
    e.preventDefault()
    that = this
    $.ajax(url: $(this).attr("href")).done (data) ->
      drawer = $(that).parents('.drawer')
      drawer.find('ul.list').append(data.html)
      $(that).parents('.view-all').remove()
      drawer.css('height', drawer.getContentHeight())