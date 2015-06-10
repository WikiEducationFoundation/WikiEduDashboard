React             = require 'react'
Router            = require 'react-router'
Link              = Router.Link
RouteHandler      = Router.RouteHandler
HandlerInterface  = require './highlevels/handler'
ServerActions     = require '../actions/server_actions'
CourseStore       = require '../stores/course_store'

getState = ->
  course: CourseStore.getCourse()

Course = React.createClass(
  displayName: 'Course'
  mixins: [CourseStore.mixin]
  contextTypes:
    router: React.PropTypes.func.isRequired
  componentWillMount: ->
    ServerActions.fetchCourse @getCourseID()
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  transitionTo: (to, params=null) ->
    @context.router.transitionTo(to, params || @routeParams())
  getCourseID: ->
    params = @context.router.getCurrentParams()
    return params.course_school + '/' + params.course_title
  getCurrentUser: ->
    if $('#react_root').attr('data-current_user')
      $('#react_root').data('current_user')
    else null
  routeParams: ->
    @context.router.getCurrentParams()
  render: ->
    route_params = @context.router.getCurrentParams()

    if !(@state.course.listed || @state.course.approved || @state.course.published) && @getCurrentUser.role == 1
      alert = (
        <div className="container alert module">
          <p>You will be able to delete this course as long as it remains unapproved and unpublished. <a href='#'>Click here</a> to delete the course now.</p>
        </div>
      )

    if @state.course.id >= 10000
      timeline = (
        <div className="nav__item" id="timeline-link">
          <p><Link params={route_params} to="timeline">Timeline</Link></p>
        </div>
      )

    <div>
      <header className='course-page'>
        <div className="container">
          <div className="title">
            <a href={@state.course.url} target="_blank">
              <h2>{@state.course.title}</h2>
            </a>
          </div>
          <div className="stat-display">
            <div className="stat-display__stat" id="articles-created">
              <h3>{@state.course.created_count}</h3>
              <small>Articles Created</small>
            </div>
            <div className="stat-display__stat" id="articles-edited">
              <h3>{@state.course.edited_count}</h3>
              <small>Articles Edited</small>
            </div>
            <div className="stat-display__stat" id="total-edits">
              <h3>{@state.course.edit_count}</h3>
              <small>Total Edits</small>
            </div>
            <div className="stat-display__stat popover-trigger" id="student-editors">
              <h3>{@state.course.student_count}</h3>
              <small>Student Editors</small>
              <div className="popover dark" id="trained-count">
                <h4>{@state.course.trained_count}</h4>
                <p>have completed training</p>
              </div>
            </div>
            <div className="stat-display__stat" id="characters-added">
              <h3>{@state.course.character_count}</h3>
              <small>Chars Added</small>
            </div>
            <div className="stat-display__stat" id="view-count">
              <h3>{@state.course.view_count}</h3>
              <small>Article Views</small>
            </div>
          </div>
        </div>
      </header>
      <div className="course_navigation">
        <nav className='container'>
          <div className="nav__item" id="overview-link">
            <p><Link params={route_params} to="overview">Overview</Link></p>
          </div>
          {timeline}
          <div className="nav__item" id="activity-link">
            <p><Link params={route_params} to="activity">Activity</Link></p>
          </div>
          <div className="nav__item" id="students-link">
            <p><Link params={route_params} to="students">Students</Link></p>
          </div>
          <div className="nav__item" id="articles-link">
            <p><Link params={route_params} to="articles">Articles</Link></p>
          </div>
          <div className="nav__item" id="uploads-link">
            <p><Link params={route_params} to="uploads">Uploads</Link></p>
          </div>
        </nav>
      </div>
      {alert}
      <div className="course_main container">
        <RouteHandler {...@props}
          course_id={@getCourseID()}
          current_user={@getCurrentUser()}
          transitionTo={@transitionTo}
        />
      </div>
    </div>
)

module.exports = Course


# <header className="course-page" data-current_user="<%= user_signed_in? ? current_user.roles(@course).to_json : { admin: false } %>">
#   <div className="container">
#     <div class="title">
#       <a href="<%= @course.url %>" target="_blank"><h2><%= @course.title %></h2></a>
#     </div>
#     <div class="stat-display">
#       <div class="stat-display__stat" id="articles-created">
#         <h3><%= number_to_human @course.revisions.joins(:article).where(articles: {namespace: 0}).where(new_article: true).count %></h3>
#         <small><%= t("metrics.articles_created") %></small>
#       </div>
#       <div class="stat-display__stat" id="articles-edited">
#         <h3><%= number_to_human @course.article_count %></h3>
#         <small><%= t("metrics.articles_edited") %></small>
#       </div>
#       <div class="stat-display__stat" id="total-edits">
#         <h3><%= number_to_human @course.revisions.count %></h3>
#         <small><%= t("metrics.edit_count_description") %></small>
#       </div>
#       <div class="stat-display__stat popover-trigger" id="student-editors">
#         <h3><%= @course.user_count %></h3>
#         <small><%= t("metrics.student_editors") %></small>
#         <div class="popover dark" id="trained-count">
#           <h4><%= @course.users.role('student').where(trained: true).count %></h4>
#           <p><%= t("user.training_complete", count: @course.users.role('student').where(trained: true).count) %></p>
#         </div>
#       </div>
#       <div class="stat-display__stat" id="characters-added">
#         <h3><%= number_to_human @course.character_sum %></h3>
#         <small><%= t("metrics.char_added") %></small>
#       </div>
#       <div class="stat-display__stat" id="view-count">
#         <h3><%= number_to_human @course.view_sum %></h3>
#         <small><%= t("metrics.view_count_description") %></small>
#       </div>
#     </div>
#   </div>
# </header>


# <div class="course_navigation">
#   <div class="nav__item <%= page == 0 ? 'active' : '' %>" id="overview-link">
#     <p><%= link_to t("course.overview"), course_slug_path(@course.slug) %></p>
#   </div>
#   <div class="nav__item <%= page == 3 ? 'active' : '' %>" id="timeline-link">
#     <p><%= link_to t("course.timeline"), :action => "timeline" %></p>
#   </div>
#   <div class="nav__item <%= page == 4 ? 'active' : '' %>" id="activity-link">
#     <p><%= link_to t("course.activity"), :action => "activity" %></p>
#   </div>
#   <div class="nav__item <%= page == 1 ? 'active' : '' %>" id="students-link">
#     <p><%= link_to t("course.students"), :action => "students" %></p>
#   </div>
#   <div class="nav__item <%= page == 2 ? 'active' : '' %>" id="articles-link">
#     <p><%= link_to t("course.articles"), :action => "articles" %></p>
#   </div>
#   <div class="nav__item <%= page == 5 ? 'active' : '' %>" id="uploads-link">
#     <p><%= link_to t("course.uploads"), :action => "uploads" %></p>
#   </div>
# </div>

# <% if !current?(@course) && user_signed_in? && @course.start < Time.now %>
# <div class="container">
#   <div class="alert module">
#     <div class="container">
#       <p>This course has ended and the data here may be out of date. <%= link_to 'Click here', {:action => 'manual_update'}, class: 'manual_update', rel: 'nofollow' %> to pull new data.</p>
#     </div>
#   </div>
# </div>
# <% end %>
# <% if !(@course.listed || @course.approved || @course.published) && current_user.can_edit?(@course) %>
# <div class="container">
#   <div class="alert module">
#     <div class="container">
#       <p>You will be able to delete this course as long as it remains unapproved and unpublished. <%= link_to 'Click here', course_slug_path(@course.slug), method: :delete, data: { confirm: 'Are you sure you want to delete this course?' } %> to delete the course now.</p>
#     </div>
#   </div>
# </div>
# <% end %>