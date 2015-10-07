McFly = require 'mcfly'
Flux  = new McFly()

_module = {}

setModule = (trainingModule) ->
  _module = trainingModule
  TrainingStore.emitChange()


TrainingStore = Flux.createStore
  getSlides: ->
    return _module.slides
  getTrainingModule: ->
    return _module
  getPreviousSlide: (props) ->
    currentSlide = @getCurrentSlide(props)
    return {} if !currentSlide || currentSlide.id is 1
    slides = @getSlides()
    if slides && props?.params
      return slides[_.findIndex(slides, (slide) -> slide.slug == props.params.slide_id) - 1]
  getNextSlide: (props) ->
    currentSlide = @getCurrentSlide(props)
    return {} if !currentSlide || currentSlide.id == _module.slides.length
    slides = @getSlides()
    if slides && props?.params
      return slides[_.findIndex(slides, (slide) -> slide.slug == props.params.slide_id) + 1]
  getCurrentSlide: (props) ->
    slides = @getSlides()
    if slides && props?.params
      return slides[_.findIndex(slides, (slide) -> slide.slug == props.params.slide_id)]
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_TRAINING_MODULES'
      setModule data.training_module
      break

module.exports = TrainingStore
