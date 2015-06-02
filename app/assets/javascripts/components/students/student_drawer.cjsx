React             = require 'react/addons'
StudentActions    = require '../../actions/student_actions'

StudentDrawer = React.createClass(
  displayName: 'StudentDrawer'
  render: ->
    <tr className='drawer'></tr>
)

module.exports = StudentDrawer