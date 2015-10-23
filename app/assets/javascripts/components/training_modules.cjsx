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
      modules = @props.block_modules.map (module) ->
        link = "/training/students/#{module.slug}"
        (
          <tr className="training-module">
            <td>{module.name}</td>
            <td className="training-module__link"><a href={link}>View</a></td>
          </tr>
        )
      content = (
        <div>
          <h3>Training</h3>
          <table>
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
