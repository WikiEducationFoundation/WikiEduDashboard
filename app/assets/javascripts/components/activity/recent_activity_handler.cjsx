React        = require 'react'
ReactRouter  = require 'react-router'
Router       = ReactRouter.Router
Link         = ReactRouter.Link

DidYouKnowHandler = require './did_you_know_handler'
PlagiarismHandler = require './plagiarism_handler'
RecentEditsHandler = require './recent_edits_handler'

RecentActivityHandler = React.createClass(
  displayName: 'RecentActivityHandler'
  render: ->

    dIYEligible = I18n.t('recent_activity.did_you_know_eligible')
    plagiarism = I18n.t('recent_activity.possible_plagiarism')
    recentEdits = I18n.t('recent_activity.recent_edits')

    <div className='container recent-activity__container'>
      <nav className='container'>
        <div className="nav__item" id="dyk-link">
          <p><Link to="/recent-activity">{dIYEligible}</Link></p>
        </div>
        <div className="nav__item" id="plagiarism-link">
          <p><Link to="/recent-activity/plagiarism">{plagiarism}</Link></p>
        </div>
        <div className="nav__item" id="recent-edits-link">
          <p><Link to="/recent-activity/recent-edits">{recentEdits}</Link></p>
        </div>
      </nav>
      {@props.children}
    </div>
)

module.exports = RecentActivityHandler
