React     = require 'react/addons'
LinkMixin = require '../../mixins/link_mixin'

Option    = require './option'

Panel = React.createClass(
  displayName: 'Panel'
  mixins: [LinkMixin]
  advance: ->
    answer_key = 0
    @props.advance(@props.key, answer_key)
  render: ->
    options = this.props.options.map (option, i) ->
      <Option {...option} key={i + Date.now()} />
    classes = 'wizard__panel'
    classes += ' active' if @props.active
    <div className={classes}>
      <h1>{this.props.title}</h1>
      <p>{this.props.description}</p>
      {options}
      {@link('timeline', 'Cancel', 'button large')}
      <div className="button dark large" onClick={@advance}>Next</div>
    </div>
)

module.exports = Panel
