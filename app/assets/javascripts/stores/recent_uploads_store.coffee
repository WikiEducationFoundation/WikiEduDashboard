McFly       = require 'mcfly'
Flux        = new McFly()

_uploads = []

setUploads = (data) ->
  RecentUploadsStore.empty()
  data.uploads.map (upload) -> _uploads.push(upload)
  RecentUploadsStore.emitChange()

RecentUploadsStore = Flux.createStore
  empty: ->
    _uploads.length = 0
  getUploads: ->
    return _uploads
, (payload) ->
  data = payload.data
  switch(payload.actionType)
    when 'RECEIVE_RECENT_UPLOADS'
      setUploads data
      break


module.exports = RecentUploadsStore
