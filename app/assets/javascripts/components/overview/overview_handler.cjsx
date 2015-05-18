React         = require 'react'
Description   = require './description'
Details       = require './details'
Grading       = require './grading'
ThisWeek      = require '../timeline/this_week'
Handler       = require '../highlevels/handler'

Overview = React.createClass(
  displayName: 'Overview'
  render: ->
    <div className='overview'>
      <div className='primary'>
        <Description {...@props} />
        <ThisWeek {...@props} />
      </div>
      <div className='sidebar'>
        <Details {...@props} />
      </div>
    </div>
)

module.exports = Handler(Overview)