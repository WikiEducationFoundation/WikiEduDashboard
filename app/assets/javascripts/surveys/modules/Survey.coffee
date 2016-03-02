require 'velocity-animate'
require 'parsleyjs'
throttle = require 'lodash.throttle'

scroll_duration = 500
scroll_easing = [0.19, 1, 0.22, 1]

Survey =
  current_block: 0
  waypoints: []

  init: ->
    @$window = $(window)
    scroll(0,0)
    @$survey_form = $('[data-survey-form]')
    @survey_blocks = $('[data-survey-block]')
    @setFormValidationSections()
    @survey_progress = $('[data-survey-progress]')
    @listeners()
    @initBlocks()

  listeners: ->
    # $('[data-survey-block]').on 'click', @handleBlockClick.bind(@)
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
    window.scrollTo(0,0)
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
    $errorsEl = $block.find('[data-errors]')
    validation = @$survey_form.parsley({uiEnabled: false}).validate group: "#{$block.data 'parsley-group'}"
    if validation is true
      $errorsEl.empty()
      return true
    else
      console.log(validation)
      validation
      return false

  setFormValidationSections: ->
    @survey_blocks.each (i, block) => 
      $block = $(block)
      $block.attr 'data-parsley-group', "block#{i}"
      $block.find(':input').attr 'data-parsley-group', "block#{i}"

  handleRequiredQuestion: ->
    $(@survey_blocks[@current_block]).addClass 'highlight'

  focusField: ->
    $(@survey_blocks[@current_block]).find('input, textarea').first().focus()

  updateProgress: (index) ->
    width = "#{(index / (@survey_blocks.length - 1)) * 100}%"
    @survey_progress.css 'width', width

  handleBlockClick: (e) ->
    $block = $($(e.target).closest('[data-survey-block]'))
    index = $block.data 'survey-block'
    $block.removeClass 'disabled'
    return if index is @current_block
    $(@survey_blocks[@current_block]).addClass 'disabled'
    @current_block = index

module.exports = Survey 