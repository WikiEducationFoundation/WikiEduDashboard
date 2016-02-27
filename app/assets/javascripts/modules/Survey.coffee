require 'waypoints/lib/jquery.waypoints'
require 'waypoints/lib/shortcuts/inview'
require 'velocity-animate'

scroll_duration = 1000
scroll_easing = [0.19, 1, 0.22, 1]

Survey =
  current_block: 0
  waypoints: []

  init: ->
    @survey_blocks = $('[data-survey-block]')
    @survey_progress = $('[data-survey-progress]')
    @listeners()
    @initBlocks()

  listeners: ->
    $('[data-survey-block]').on 'click', @handleBlockClick.bind(@)
    $('[data-next-survey-block]').on 'click', @nextBlock.bind(@)
    $('[data-prev-survey-block]').on 'click', @prevBlock.bind(@)
    $('[data-survey-block] input[type=checkbox], [data-survey-block] input[type=radio]').on 'change', @nextBlock.bind(@)
    # @survey_blocks.each (i, block) =>
    #   $el = $(block)
    #   @waypoints.push new Waypoint.Inview
    #     element: block
    #     entered: (dir) =>
    #       index = $el.index()
    #       console.log index
    #       return if index is @current_block
    #       $(@survey_blocks[@current_block]).addClass 'disabled'    
    #       $(@survey_blocks[index]).removeClass 'disabled'    
    #       @current_block = index

  initBlocks: ->
    $(@survey_blocks[@current_block]).removeClass 'disabled'

  nextBlock: (e) ->
    e.preventDefault()
    return if @animating
    toIndex = @current_block + 1
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
        @updateProgress()

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
        @updateProgress()

  focusField: ->
    $(@survey_blocks[@current_block]).find('input, textarea').first().focus()

  updateProgress: ->
    width = 0
    if @current_block > 0
      width = "#{(@current_block / (@survey_blocks.length - 1)) * 100}%"
    @survey_progress.css 'width', width

  handleBlockClick: (e) ->
    $block = $($(e.target).closest('[data-survey-block]'))
    index = $block.index()
    return if index is @current_block
    $(@survey_blocks[index]).removeClass 'disabled'    
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