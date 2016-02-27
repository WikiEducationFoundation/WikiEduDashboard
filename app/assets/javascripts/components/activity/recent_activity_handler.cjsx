React        = require 'react'
ReactRouter  = require 'react-router'
Router       = ReactRouter.Router
Link         = ReactRouter.Link

DidYouKnowHandler = require './did_you_know_handler.cjsx'
PlagiarismHandler = require './plagiarism_handler.cjsx'
RecentEditsHandler = require './recent_edits_handler.cjsx'

RecentActivityHandler = React.createClass(
  displayName: 'RecentActivityHandler'
  render: ->
    <div className='container recent-activity__container'>
      <nav className='container'>
        <div className="nav__item" id="dyk-link">
          <p><Link to="recent-activity">Did You Know Eligible</Link></p>
        </div>
        <div className="nav__item" id="plagiarism-link">
          <p><Link to="recent-activity/plagiarism">Possible Plagiarism</Link></p>
        </div>
        <div className="nav__item" id="recent-edits-link">
          <p><Link to="recent-activity/recent-edits">Recent Edits</Link></p>
        </div>
      </nav>
      {@props.children}
    </div>
)

module.exports = RecentActivityHandler
