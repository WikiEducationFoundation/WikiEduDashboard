React = require 'react'
TrainingStore = require '../stores/training_store'
TrainingActions = require '../actions/training_actions'
ServerActions = require '../../actions/server_actions'
Router          = require 'react-router'
Link            = Router.Link
SlideLink       = require './slide_link'
SlideMenu       = require './slide_menu'
Quiz            = require './quiz'
md              = require('markdown-it')({ html: true, linkify: true })

getState = (props) ->
  slides: TrainingStore.getSlides()
  currentSlide: TrainingStore.getCurrentSlide()
  previousSlide: TrainingStore.getPreviousSlide(props)
  nextSlide: TrainingStore.getNextSlide(props)
  menuIsOpen: TrainingStore.getMenuState()

TrainingSlideHandler = React.createClass(
  displayName: 'TrainingSlideHandler'
  mixins: [TrainingStore.mixin]
  getInitialState: ->
    slides: []
    previousSlide: { slug: '' }
    currentSlide: TrainingStore.getCurrentSlide()
    nextSlide: { slug: '' }
    menuIsOpen: false
  moduleId: ->
    @props.params.module_id
  componentDidMount: ->
    getState(@props)
  componentWillReceiveProps: (newProps) ->
    TrainingActions.setCurrentSlide(newProps.params.slide_id)
    @setState getState(newProps)
  componentWillMount: ->
    ServerActions.fetchTrainingModule(module_id: @moduleId(), current_slide_id: @props.params.slide_id)
  storeDidChange: ->
    @setState getState(@props)
  toggleMenuOpen: ->
    TrainingActions.toggleMenuOpen(currently: @state.menuIsOpen)
  render: ->
    disableNext = @state.currentSlide.assessment? && !@state.currentSlide.answeredCorrectly

    if @state.nextSlide?.slug
      nextLink = <SlideLink
                    slideId={@state.nextSlide.slug}
                    direction='Next'
                    disabled={disableNext}
                    slideTitle={@state.nextSlide.title}
                    button=true
                    {... @props} />

    if @state.previousSlide?.slug
      previousLink = <SlideLink
                       slideId={@state.previousSlide.slug}
                       direction='Previous'
                       slideTitle={@state.previousSlide.title}
                       {... @props} />
 
    raw_html = md.render(@state.currentSlide.content)
    menuClass = if @state.menuIsOpen is false then 'hidden' else 'shown'

    if @state.currentSlide.assessment
      assessment = @state.currentSlide.assessment
      quiz = <Quiz
        question={assessment.question}
        answers={assessment.answers}
        selectedAnswer={@state.currentSlide.selectedAnswer}
        correctAnswer={@state.currentSlide.assessment.correct_answer_id}
      />

    <article className="training__slide">
      <header>
        <h3 className="pull-left">{@state.currentSlide.title}</h3>
        <div className="pull-right training__slide__nav" onClick={@toggleMenuOpen}>
          <h3 className="pull-left">Page {@state.currentSlide.id} of {@state.slides.length}</h3>
          <div className="pull-right hamburger">
            <span className="hamburger__bar"></span>
            <span className="hamburger__bar"></span>
            <span className="hamburger__bar"></span>
          </div>
        </div>
        <SlideMenu
          onClick={@toggleMenuOpen}
          menuClass={menuClass}
          currentSlide={@state.currentSlide}
          params={@props.params}
          slides={@state.slides} />
      </header>
      <div className='markdown training__slide__content' dangerouslySetInnerHTML={{__html: raw_html}}></div>
      {quiz}
      <footer className="training__slide__footer">
       <span className="pull-left">{previousLink}</span>
       <span  className="pull-right">{nextLink}</span>
      </footer>
    </article>
)

module.exports = TrainingSlideHandler
