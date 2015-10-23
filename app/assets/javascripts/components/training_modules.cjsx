React = require 'react'
md    = require('markdown-it')({ html: true, linkify: true })
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
            name='foo'
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
        raw_html = md.render(module.intro)
        (
          <div>
            <br /><br />
            <p>{module.name}</p>
            <div dangerouslySetInnerHTML={{__html: raw_html}}></div>
            <hr />
            <p><a href={link}>Go to training</a></p>
          </div>
        )
      content = (
        <div>
          <br />
          <h3>Training</h3>
          {modules}
        </div>
      )

    <div>
      {content}
    </div>

)

module.exports = TrainingModules
