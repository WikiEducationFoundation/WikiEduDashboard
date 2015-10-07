React = require 'react'
TrainingStore = require '../stores/training_store'
ServerActions = require '../../actions/server_actions'
Router          = require 'react-router'
Link            = Router.Link
md              = require('markdown-it')({ html: true, linkify: true })

getState = (props) ->
  slides: TrainingStore.getSlides()
  currentSlide: TrainingStore.getCurrentSlide(props)
  previousSlide: TrainingStore.getPreviousSlide(props)
  nextSlide: TrainingStore.getNextSlide(props)

TrainingSlideHandler = React.createClass(
  displayName: 'TrainingSlideHandler'
  mixins: [TrainingStore.mixin]
  getInitialState: ->
    slides: []
    previousSlide: { slug: '' }
    nextSlide: { slug: '' }
    currentSlide: {
      id: null
      title: ''
      content: 'waiting'
    }
  moduleId: ->
    @props.params.module_id
  componentDidMount: ->
    getState(@props)
  componentWillReceiveProps: (newProps) ->
    @setState getState(newProps)
  componentWillMount: ->
    ServerActions.fetchTrainingModule(module_id: @moduleId())
  storeDidChange: ->
    @setState getState(@props)
  render: ->
    console.log 'rendered'

    if @state.nextSlide.slug
      nextLink = (<Link to="slide" params={{ library_id: @props.params.library_id, module_id: @props.params.module_id, slide_id: @state.nextSlide.slug }}>Next Slide: {@state.nextSlide.title}</Link>)
    else
      ''

    if @state.previousSlide.slug
      previousLink = (<Link to="slide" params={{ library_id: @props.params.library_id, module_id: @props.params.module_id, slide_id: @state.previousSlide.slug }}>Previous Slide: {@state.previousSlide.title}</Link>)
    else
      ''

    raw_html = md.render(@state.currentSlide.content)

    <article className="training__slide">
      <header className="appearance-hr">
        <h3 className="pull-left">{@state.currentSlide.title}</h3>
        <h3 className="pull-right">Page {@state.currentSlide.id} of {@state.slides.length}</h3>
      </header>
      <div className='markdown' dangerouslySetInnerHTML={{__html: raw_html}}></div>
      <footer>
       <span className="pull-left">{previousLink}</span>
       <span className="pull-right">{nextLink}</span>
      </footer>
    </article>
)

module.exports = TrainingSlideHandler
