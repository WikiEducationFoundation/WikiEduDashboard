React = require 'react'
TrainingStore = require '../stores/training_store'
ServerActions = require '../../actions/server_actions'

Router          = require 'react-router'
RouteHandler    = Router.RouteHandler

getState = ->
  training_module: TrainingStore.getTrainingModule()

TrainingModuleHandler = React.createClass(
  mixins: [TrainingStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  componentWillMount: ->
    module_id = document.getElementById('react_root').dataset.moduleId
    ServerActions.fetchTrainingModule(module_id: module_id)
  render: ->
    slides = _.compact(@state.training_module.slides).map (slide) ->
      <li>
        <h3>{slide.title}</h3>
        <p>{slide.summary}</p>
      </li>

    <div className='training__toc-container'>
      <h1><small className="heading appearance-hr">Table of Contents</small></h1>
      <ol>
      {slides}
      </ol>
    </div>
)

module.exports = TrainingModuleHandler

