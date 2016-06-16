React         = require 'react'
ReactRouter   = require 'react-router'
Select        = require 'react-select'
Router        = ReactRouter.Router
Link          = ReactRouter.Link
Expandable    = require '../high_order/expandable.cjsx'
Popover       = require('../common/popover.jsx').default
Lookup        = require '../common/lookup.cjsx'
ServerActions = require('../../actions/server_actions.js').default
AssignmentActions = require('../../actions/assignment_actions.js').default
AssignmentStore   = require '../../stores/assignment_store.coffee'
CourseUtils       = require('../../utils/course_utils.js').default
shallowCompare = require 'react-addons-shallow-compare'
NotificationActions = require('../../actions/notification_actions.js').default

AssignButton = React.createClass(
  displayName: 'AssignButton'
  stop: (e) ->
    e.stopPropagation()
  getKey: ->
    tag = if @props.role == 0 then 'assign_' else 'review_'
    if @props.student
      return tag + @props.student.id
    else
      return tag
  getInitialState: ->
    return {
      showOptions: false
      language: @props.course.home_wiki.language
      project: @props.course.home_wiki.project
    }
  shouldComponentUpdate: (nextProps, nextState) ->
    shallowCompare(this, nextProps, nextState)
  handleShowOptions: (e) ->
    e.preventDefault()
    @setState
      showOptions: true
  handleChangeTitle: (e) ->
    e.preventDefault()
    title = e.target.value
    assignment = CourseUtils.articleFromTitleInput title
    language = assignment.language ? @state.language
    project = assignment.project ? @state.project
    @setState
      title: assignment.title
      project: project
      language: language
  handleChangeLanguage: (val) ->
    @setState
      language: val
  handleChangeProject: (val) ->
    @setState
      project: val
  assign: (e) ->
    e.preventDefault()

    if @props.student
      student = @props.student.id
    else
      student = null

    assignment =
      title: decodeURIComponent(@state.title).trim()
      project: @state.project
      language: @state.language
      course_id: @props.course_id
      user_id: student
      role: @props.role

    if assignment.title == "" || assignment.title == "undefined"
      NotificationActions.addNotification
        message: I18n.t('error.article_required')
        closable: true
        type: 'error'
      return

    article_title = assignment.title

    # Check if the assignment exists
    if @props.student && AssignmentStore.getFiltered({
      article_title: article_title,
      user_id: @props.student.id,
      role: @props.role
    }).length != 0
      alert I18n.t("assignments.already_exists")
      return

    # Confirm
    if @props.student
      return unless confirm I18n.t('assignments.confirm_addition', {
        title: article_title,
        username: @props.student.username
      })
    else
      return unless confirm I18n.t('assignments.confirm_add_available', {
        title: article_title
      })

    # Send
    if(assignment)
      # Update the store
      AssignmentActions.addAssignment assignment
      # Post the new assignment to the server
      ServerActions.addAssignment assignment
      @refs.lookup.clear()
      @setState(@getInitialState())
  unassign: (assignment) ->
    return unless confirm(I18n.t('assignments.confirm_deletion'))
    # Update the store
    AssignmentActions.deleteAssignment assignment
    # Send the delete request to the server
    ServerActions.deleteAssignment assignment
  render: ->
    className = 'button border'
    className += ' dark' if @props.is_open

    if @props.assignments.length > 1 || (@props.assignments.length > 0 && @props.permitted)
      raw_a = @props.assignments[0]
      show_button = <button className={className + ' plus'} onClick={@props.open}>+</button>
    else if @props.permitted
      if @props.add_available
        assign_text = I18n.t("assignments.add_available")
      else if @props.student && @props.current_user.id == @props.student.id
        assign_text = I18n.t("assignments.assign_self")
        review_text = I18n.t("assignments.review_self")
      else if @props.current_user.role > 0 || @props.current_user.admin
        assign_text = I18n.t("assignments.assign_other")
        review_text = I18n.t("assignments.review_other")
      final_text = if @props.role == 0 then assign_text else review_text
      edit_button = (
        <button className={className} onClick={@props.open}>{final_text}</button>
      )

    assignments = @props.assignments.map (ass) =>
      ass.course_id = @props.course_id
      article = CourseUtils.articleFromAssignment(ass)
      if @props.permitted
        remove_button = <button className='button border plus' onClick={@unassign.bind(@, ass)}>-</button>
      if article.url?
        link = <a href={article.url} target='_blank' className='inline'>{article.formatted_title}</a>
      else
        link = <span>{article.formatted_title}</span>
      <tr key={ass.id}>
        <td>{link}{remove_button}</td>
      </tr>

    if @props.assignments.length == 0 && @props.student
      assignments = <tr><td>{I18n.t("assignments.none_short")}</td></tr>

    if @props.permitted
      if @state.showOptions
        languageOptions = WikiLanguages.map (language) =>
          {label: language, value: language}

        projectOptions = WikiProjects.map (project) =>
          {label: project, value: project}

        options = (
          <fieldset className="mt1">
            <Select
              ref='languageSelect'
              className='half-width-select-left language-select'
              name='language'
              placeholder='Language'
              onChange={@handleChangeLanguage}
              value={@state.language}
              options={languageOptions}
            />
            <Select
              name='project'
              ref='projectSelect'
              className='half-width-select-right project-select'
              onChange={@handleChangeProject}
              placeholder='Project'
              value={@state.project}
              options={projectOptions}
            />
          </fieldset>
        )
      else
        options = (
          <div className="small-block-link">
            {@state.language}.{@state.project}.org <a href="#" onClick={@handleShowOptions}>({I18n.t('application.change')})</a>
          </div>
        )

      edit_row = (
        <tr className='edit'>
          <td>
            <form onSubmit={@assign}>
              <Lookup model='article'
                placeholder={I18n.t("articles.title_example")}
                ref='lookup'
                value={@state.title}
                onSubmit={@assign}
                onChange={@handleChangeTitle}
                disabled=true
              />
              <button className='button border' type="submit">{I18n.t("assignments.label")}</button>
              {options}
            </form>
          </td>
        </tr>
      )


    <div className='pop__container' onClick={@stop}>
      {show_button}
      {edit_button}
      <Popover
        is_open={@props.is_open}
        edit_row={edit_row}
        rows={assignments}
      />
    </div>
)

module.exports = Expandable(AssignButton)
