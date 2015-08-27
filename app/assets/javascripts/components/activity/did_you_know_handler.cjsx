React        = require 'react/addons'
Router       = require 'react-router'
RouteHandler = Router.RouteHandler
DidYouKnowStore = require '../../stores/did_you_know_store'

ServerActions = require '../../actions/server_actions'
TransitionGroup = require '../../utils/TransitionGroup'

getState = ->
  articles: DidYouKnowStore.getArticles()

DidYouKnowHandler = React.createClass(
  displayName: 'DidYouKnowHandler'
  mixins: [DidYouKnowStore.mixin]
  getInitialState: ->
    getState()
  storeDidChange: ->
    @setState getState()
  componentWillMount: ->
    ServerActions.fetchDYKArticles()
  render: ->
    elements = @state.articles.map (article) ->
      <tr className='dyk-article'>
        <td className='popover-trigger desktop-only-tc'>
          {article.title}
        </td>
        <td>
          {article.revision_score}
        </td>
        <td>
          {article.user_wiki_id}
        </td>
        <td>
          {moment(article.revision_datetime).format('YYYY/MM/DD h:mm a')}
        </td>
      </tr>

    <table className='dyk-articles list'>
      <thead>
        <tr>
          <th>
            Article Title
          </th>
          <th>
            Revision Score
          </th>
          <th>
            Revision Author
          </th>
          <th>
            Revision Date/Time
          </th>
        </tr>
      </thead>
      <TransitionGroup
        transitionName={'dyk'}
        component='tbody'
        enterTimeout={500}
        leaveTimeout={500}
      >
        {elements}
      </TransitionGroup>
    </table>
)

module.exports = DidYouKnowHandler
