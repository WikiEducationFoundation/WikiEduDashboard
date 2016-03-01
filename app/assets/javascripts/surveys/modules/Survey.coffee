require 'velocity-animate'
throttle = require 'lodash.throttle'

scroll_duration = 500
scroll_easing = [0.19, 1, 0.22, 1]

Survey =
  current_block: 0
  waypoints: []

  init: ->
    @$window = $(window)
    window.scrollTo(0,0)
    @survey_blocks = $('[data-survey-block]')
    @survey_progress = $('[data-survey-progress]')
    @listeners()
    @initBlocks()

  listeners: ->
    $('[data-survey-block]').on 'click', @handleBlockClick.bind(@)
    $('[data-next-survey-block]').on 'click', @nextBlock.bind(@)
    $('[data-prev-survey-block]').on 'click', @prevBlock.bind(@)
    $('[data-survey-block] input[type=checkbox], [data-survey-block] input[type=radio]').on 'change', @nextBlock.bind(@)
    @$window.scroll( throttle( @handleScroll.bind(@), 250) );

  handleScroll: ->
    docHeight = @$window.innerHeight()
    toTop = @$window.scrollTop()
    wH = @$window.innerHeight()
    threshold =  (@$window.scrollTop() + wH) - wH * .3
    @survey_blocks.each (i, block) =>
      $block = $(block)
      blockOffset = $block.offset().top
      if blockOffset > toTop && blockOffset < threshold
        $block.removeClass 'disabled'
      else
        $block.addClass 'disabled'

  initBlocks: ->
    $(@survey_blocks[@current_block]).removeClass 'disabled not-seen'

  nextBlock: (e) ->
    e.preventDefault()
    return if @animating
    toIndex = @current_block + 1
    $block = $(@survey_blocks[toIndex])

    passedValidation = @validateCurrentQuestion()

    if passedValidation
      $($block).velocity 'scroll', 
        duration: scroll_duration
        easing: scroll_easing
        offset: -200
        begin: =>
          $(@survey_blocks[@current_block]).removeClass 'highlight' 
          $(@survey_blocks[@current_block]).addClass 'disabled'
          @updateProgress(toIndex)
        complete: =>
          @animating = false
          @current_block = toIndex
          @focusField()

      $block.velocity {opacity: [1, 0], translateY: ['0%', '100%']},
        queue: false
        complete: =>
          $block.removeClass 'disabled not-seen' 
    else
      @handleRequiredQuestion()
      return
        

  prevBlock: (e) ->
    e.preventDefault()
    return if @animating
    toIndex = @current_block - 1
    $(@survey_blocks[toIndex]).velocity 'scroll', 
      duration: scroll_duration
      easing: scroll_easing
      offset: -200
      begin: =>
        @animating = true
        $(@survey_blocks[toIndex]).removeClass 'disabled' 
        $(@survey_blocks[@current_block]).addClass 'disabled' 
      complete: =>  
        @animating = false
        @current_block = toIndex
        @focusField()

  validateCurrentQuestion: ->
    $block = $(@survey_blocks[@current_block])
    isRequired = $block.hasClass 'required'
    console.log $block.find('input').val()
    !isRequired

  handleRequiredQuestion: ->
    $(@survey_blocks[@current_block]).addClass 'highlight'

  focusField: ->
    $(@survey_blocks[@current_block]).find('input, textarea').first().focus()

  updateProgress: (index) ->
    # width = 0
    width = "#{(index / (@survey_blocks.length - 1)) * 100}%"
    @survey_progress.css 'width', width

  handleBlockClick: (e) ->
    $block = $($(e.target).closest('[data-survey-block]'))
    index = $block.data 'survey-block'
    $block.removeClass 'disabled'
    return if index is @current_block
    $(@survey_blocks[@current_block]).addClass 'disabled'
    @current_block = index

  handleInView: (e, isInView, topOrBottomOrBoth) ->
    $el = $(e.target)
    index = $el.index()
    return if index is @current_block
    if isInView
      $(@survey_blocks[@current_block]).addClass 'disabled' 
      $(@survey_blocks[index]).removeClass 'disabled' 
      @current_block = index

    console.log e, isInView, $(e.target).index(), topOrBottomOrBoth

module.exports = Survey 