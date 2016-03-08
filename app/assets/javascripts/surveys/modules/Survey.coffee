require 'velocity-animate'
require 'parsleyjs'
rangeslider = require 'rangeslider.js'
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
    @initRangeSliders()

  listeners: ->
    $('[data-next-survey-block]').on 'click', @nextBlock.bind(@)
    $('[data-prev-survey-block]').on 'click', @prevBlock.bind(@)
    @$window.scroll( throttle( @handleScroll.bind(@), 250) );

  handleScroll: ->
    return if @animating
    docHeight = @$window.innerHeight()
    distanceToTop = @$window.scrollTop()
    windowHeight = @$window.innerHeight()
    threshold =  (distanceToTop + windowHeight) - windowHeight * .5

    @survey_blocks.each (i, block) =>
      $block = $(block)
      return if $block.hasClass 'not-seen'
      blockOffset = $block.offset().top
      if blockOffset > distanceToTop && blockOffset < threshold
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
      @removeNextButton(e)
      $($block).velocity 'scroll', 
        duration: scroll_duration
        easing: scroll_easing
        offset: -200
        begin: =>
          $(@survey_blocks[@current_block])
            .removeClass 'highlight' 
            .attr 'style', ''
          @updateProgress(toIndex)
        complete: =>
          @animating = false
          @current_block = toIndex
          @focusField()
      if $block.hasClass 'not-seen'
        $block.velocity {opacity: [1, 0], translateY: ['0%', '100%']},
          queue: false
          complete: =>
            $block.removeClass 'not-seen'

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
      complete: =>  
        @animating = false
        @current_block = toIndex
        @focusField()

  validateCurrentQuestion: ->
    $block = $(@survey_blocks[@current_block])
    $errorsEl = $block.find('[data-errors]')
    validation = @$survey_form.parsley({uiEnabled: false}).validate group: "#{$block.data 'parsley-group'}"
    if $block.find("[data-required-checkbox='true']").length
      if $block.find('input[type="checkbox"]:checked').length is 0
        validation = false

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

  removeNextButton: ({target}) ->
    return unless target?
    $el = $(target).closest '.button'
    if $el.hasClass 'button'
      $el.addClass 'hidden'

  initRangeSliders: ->
    # console.log $.rangeslider
    
    getRulerRange = (min, max, step) ->
      range = ''
      i = 0
      while i <= max
        range += i + ' '
        i = i + step
      range

    $('input[type="range"]').each (i, slider) ->
      $ruler = $('<div class="rangeslider__ruler" />')
      $(slider).rangeslider
        polyfill: false
        rangeClass: 'rangeslider'
        disabledClass: 'rangeslider--disabled'
        horizontalClass: 'rangeslider--horizontal'
        verticalClass: 'rangeslider--vertical'
        fillClass: 'rangeslider__fill'
        handleClass: 'rangeslider__handle'
        onInit: ->
          $ruler[0].innerHTML = getRulerRange(this.min, this.max, this.step)
          this.$range.prepend $ruler
        onSlide: (position, value) ->
        onSlideEnd: (position, value) ->

  # addRequiredAttributes: ->
  #   $('[data-required-checkbox="true"]').each (i, checkbox) ->
  #     $checkbox = $(checkbox).find 'input[type=checkbox]'
  #     $checkbox.attr 'required', 'required'

module.exports = Survey 