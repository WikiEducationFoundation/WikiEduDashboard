$ ->

  # Initial showing of the drawer
  $('.drawer_trigger:not(.disabled)').click (e) ->
    drawer = $(e.target).parents('.row').children('.drawer')
    return if $(e.target).is('a')

    $('.drawer').not(drawer).css('height', '0px')
    $('.row.open').not($(e.target).parents('.row')).removeClass('open')

    if(drawer.find('li').length == 0)
      $.ajax(url: drawer.attr("rel")).done (data) ->
        drawer.find('ul.list').append(data.html)
        drawer.toggleHeight()
        $(e.target).parents('.row').toggleClass('open')
        setTimeout ->
          $('html').velocity "scroll", {
            offset: $(e.target).parents('.row').offset().top - 80,
            duration: 400,
            easing: "easeInOutQuad"
          }
        , 200
    else
      drawer.toggleHeight()
      $(e.target).parents('.row').toggleClass('open')
      setTimeout ->
        console.log $(e.target).parents('.row').offset().top - 80
        $('html').velocity "scroll", {
          offset: $(e.target).parents('.row').offset().top - 80,
          duration: 400,
          easing: "easeInOutQuad"
        }
      , 200


  # Clicking the "show more contributions" link
  $('.drawer .view-all a').click (e) ->
    e.preventDefault()
    that = this
    $.ajax(url: $(this).attr("href")).done (data) ->
      drawer = $(that).parents('.drawer')
      drawer.find('ul.list').append(data.html)
      $(that).parents('.view-all').remove()
      drawer.css('height', drawer.getContentHeight())