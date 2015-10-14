React         = require 'react'
ServerActions = require '../../actions/server_actions'
CourseTrainingStore = require '../../stores/course_training_store'

getState = ->
  training_modules: CourseTrainingStore.getTrainingModules()

CourseTrainingHandler = React.createClass(
  displayName: 'CourseTraningHandler'
  mixins: [CourseTrainingStore.mixin]
  storeDidChange: ->
    @setState getState()
  getInitialState: ->
    training_modules: CourseTrainingStore.getTrainingModules()
  componentDidMount: ->
    ServerActions.fetchTrainingModulesForCourse(@props.course_id)
  render: ->
    trainingModules = _.compact(@state.training_modules).map (module) -> <li>{module.name}</li>
    <div className='section-header'>
      <h3>Training</h3>
      <ul>
        {trainingModules}
      </ul>
    </div>
)

module.exports = CourseTrainingHandler
