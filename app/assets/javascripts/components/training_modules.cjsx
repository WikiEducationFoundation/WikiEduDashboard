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
          <Select
            multi={true}
            name='block-training-modules'
            value={@state.value}
            options={options}
            onChange={@onChange}
            allowCreate={true}
            placeholder="Add training module(s)…"
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

        progressClass += ' block__training-modules-table__module-progress '
        progressClass += ' overdue' if module.overdue is true
        progressClass += ' complete' if module.deadline_status is 'complete'

        if module.deadline_status is 'overdue'
          deadlineStatus = "(due on #{module.due_date})"

        moduleStatus = if module.module_progress && module.deadline_status then (
          <div>
            {module.module_progress}
            &nbsp;
            {deadlineStatus}
          </div>
        ) else (
          '--'
        )
        (
          <tr key={module.id} className="training-module">
            <td className='block__training-modules-table__module-name'>{module.name}</td>
            <td className={progressClass}>
              {moduleStatus}
            </td>
            <td className="block__training-modules-table__module-link">
              <a className={module.module_progress} href={link}>
                {linkText}
                <i className={iconClassName}></i>
              </a>
            </td>
          </tr>
        )
      content = (
        <div>
          <h4>Training</h4>
          <table className='block__training-modules-table'>
            <thead>
              <tr>
                <td className='block__training-modules-table__module-name-header'>Module Name</td>
                <td className='block__training-modules-table__status-header'>Status</td>
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
