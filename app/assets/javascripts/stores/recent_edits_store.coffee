McFly       = require 'mcfly'
Flux        = new McFly()

_revisions = []

setRevisions = (data) ->
  RecentEditsStore.empty()
  data.revisions.map (revision) -> _revisions.push(revision)
  RecentEditsStore.emitChange()

RecentEditsStore = Flux.createStore
  empty: ->
    _revisions.length = 0
  getRevisions: ->
    return _revisions
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_RECENT_EDITS'
      setRevisions data
      break


module.exports = RecentEditsStore
