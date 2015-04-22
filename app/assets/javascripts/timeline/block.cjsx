React = require 'react'

Block = React.createClass(
  render: ->
    <div class="block">
      <a onClick={this.props.deleteBlock}>Delete</a>
      <p>{this.props.kind}</p>
      <p>{this.props.content}</p>
    </div>
)

module.exports = Block