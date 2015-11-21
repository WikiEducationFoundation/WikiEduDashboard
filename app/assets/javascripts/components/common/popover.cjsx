React = require 'react'

Popover = React.createClass(
  displayname: 'Popover'
  render: ->
    <div className={'pop' + (if @props.is_open then ' open' else '')}>
      <table>
        <tbody>
          {@props.edit_row}
          {@props.rows}
        </tbody>
      </table>
    </div>
)

module.exports = Popover
