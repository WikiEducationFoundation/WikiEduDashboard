React        = require 'react/addons'
Router       = require 'react-router'
RouteHandler = Router.RouteHandler
Link         = Router.Link

DidYouKnowHandler = require './did_you_know_handler'
MainspaceHandler  = require './mainspace_handler'
PlagiarismHandler = require './plagiarism_handler'

RecentActivityHandler = React.createClass(
  displayName: 'RecentActivityHandler'
  render: ->
    <div className='container recent-activity__container'>
      <nav className='container'>
        <div className="nav__item" id="dyk-link">
          <p><Link to="did-you-know">Did You Know Eligible</Link></p>
        </div>
        <div className="nav__item" id="mainspace-link">
          <p><Link to="mainspace">Mainspace Eligible</Link></p>
        </div>
        <div className="nav__item" id="plagiarism-link">
          <p><Link to="plagiarism">Plagiarism Flag</Link></p>
        </div>
      </nav>
      <RouteHandler {...@props} />
    </div>
)

module.exports = RecentActivityHandler
