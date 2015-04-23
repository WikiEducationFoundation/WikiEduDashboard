React = require 'react'
Router = require 'react-router'
RouteHandler = Router.RouteHandler

McFly = require 'mcfly'
Flux = new McFly()

# Store
_course = {}

fetchCourse = (slug) ->
  $.ajax
    type: 'GET',
    url: '/courses/' + slug + '.json'
    success: (data) =>
      console.log 'Got course!'
      _course = data
      TimelineStore.emitChange()
    failure: (e) ->
      console.log 'Couldn\'t get course.'

CourseStore = Flux.createStore
  getCourse: (slug) ->
    fetchCourse(slug) if _course == {}
    return _course

, (payload) ->
  return true

# Component
getState = (slug) ->
  course: CourseStore.getCourse(slug)

Course = React.createClass(
  mixins: [CourseStore.mixin]
  contextTypes:
    router: React.PropTypes.func.isRequired
  getInitialState: ->
    getState(slug)
  storeDidChange: ->
    console.log 'getting state'
    this.setState(getState(slug))
  render: ->
    <div>
      <header class="course-page">
        <div class="container">
          <div class="title">
            <h2>HELLO</h2>
            <h6>SCHOOLTERM</h6>
          </div>
        </div>
      </header>

      <section>
        <RouteHandler/>
      </section>
    </div>
)

module.exports = Course