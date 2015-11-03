React  = require 'react'
Select = require 'react-select'

TrainingModules = React.createClass(
  displayName: 'TrainingModules'
  getInitialState: ->
    ids = @props.block_modules?.map (module) -> module.id
    value: ids
  onChange: (value, values) ->
    @setState value: values
    @props.onChange(value, values)
  progressClass: (progress) ->
    linkStart = 'timeline-module__'
    if progress is 'Complete' then "#{linkStart}progress-complete " else "#{linkStart}in-progress "
  render: ->
    if @props.editable
      options = _.compact(@props.all_modules).map (module) -> (
        { value: module.id, label: module.name }
      )
      content = (
        <div>
          <h3>Training Modules:&nbsp;</h3>
          <Select
            multi={true}
            name='block-training-modules'
            value={@state.value}
            options={options}
            onChange={@onChange}
            allowCreate={true}
          />
        </div>
      )
    else
      modules = @props.block_modules.map (module) =>
        link = "/training/students/#{module.slug}"
        iconClassName = 'icon '
        if module.module_progress
          progressClass = @progressClass(module.module_progress)
          linkText = if module.module_progress is 'Complete' then 'View' else 'Continue'
          iconClassName += if module.module_progress is 'Complete' then 'icon-check' else 'icon-rt_arrow'
        else
          linkText = 'Start'
          iconClassName += 'icon-rt_arrow'

        progressClass += " #{module.assignment_status_css_class}"
        if module.assignment_deadline_status?.toString() is 'overdue'
          deadlineStatus = " (#{module.assignment_deadline_status.capitalize()})"

        (
          <tr className="training-module">
            <td>{module.name}</td>
            <td className={progressClass}>
              {module.module_progress}
              {deadlineStatus}
            </td>
            <td className="training-module__link">
              <a className={module.module_progress} href={link}>
                {linkText}
                <i className={iconClassName}></i>
              </a>
            </td>
          </tr>
        )
      content = (
        <div>
          <h3>Training</h3>
          <table>
            <thead>
              <tr>
                <td>Module Name</td>
                <td>Status</td>
              </tr>
            </thead>
            <tbody>
              {modules}
            </tbody>
          </table>
        </div>
      )

    <div className="block__training-modules">
      {content}
    </div>

)

module.exports = TrainingModules
