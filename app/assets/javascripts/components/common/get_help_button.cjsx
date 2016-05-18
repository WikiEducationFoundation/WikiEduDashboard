React         = require 'react'
Expandable    = require '../high_order/expandable.cjsx'
UserStore     = require '../../stores/user_store.coffee'

getState = ->
  contentExperts: UserStore.getFiltered({ content_expert: true })
  programManagers: UserStore.getFiltered({ program_manager: true })

GetHelpButton = React.createClass(
  mixins: [UserStore.mixin]
  displayName: 'GetHelpButton'

  getInitialState: ->
    return getState()

  storeDidChange: ->
    @setState getState()

  stop: (e) ->
    e.stopPropagation()

  getKey: ->
    return @props.key

  render: ->
    contentExperts = @state.contentExperts.map (user, index) ->
      <span key={user.username}>
        <a href={"mailto:#{user.email}"}>{user.username}</a> (Content Expert)
        <br/>
      </span>

    if @props.current_user.role > 0
      programManagers = @state.programManagers.map (user, index) ->
        <span key={user.username}>
          <a href={"mailto:#{user.email}"}>{user.username}</a> (Program Manager)
          <br/>
        </span>

    if programManagers or contentExperts
      helpers = (
        <p>
          If you still need help, reach out to your Wikipedia Content Expert:
          <br/>
          {contentExperts}
          {programManagers}
        </p>
      )

    <div className='pop__container'>
      <button className="dark button small" onClick={@props.open}>Get Help</button>
      <div className={'pop' + (if @props.is_open then ' open' else '')}>
        <div className="pop__padded-content">
          <p>
            <strong>
              Hi, if you need help with your Wikipedia assignment, you've come
              to the right place!
            </strong>
          </p>
        
          <form target="_blank" action="/ask" acceptCharset="UTF-8" method="get">
            <input name="utf8" type="hidden" defaultValue="✓" />
            <input type="text" name="q" id="q" defaultValue="" placeholder="Search Help Forum" />
            <button type="submit">
              <i className="icon icon-search"></i>
            </button>
          </form>
          
          <p>
            You may also refer to our interactive training modules and
            external resources for help with your assignment.
          </p>
          <p>
            <a href="/training" target="blank">Interactive Training</a><br/>
            <a href="#" target="blank">FAQ</a>
          </p>
          {helpers}
        </div>
      </div>
    </div>
)

module.exports = Expandable(GetHelpButton)
