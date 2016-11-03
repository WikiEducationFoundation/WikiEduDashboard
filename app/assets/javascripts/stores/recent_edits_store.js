import McFly from 'mcfly';
const Flux = new McFly();

const _revisions = [];

const setRevisions = function (data) {
  data.revisions.map(revision => _revisions.push(revision));
};

const storeMethods = {
  empty() {
    return _revisions.length = 0;
  },
  getRevisions() {
    return _revisions;
  }
};

const RecentEditsStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'RECEIVE_RECENT_EDITS':
      RecentEditsStore.empty();
      setRevisions(data);
      return RecentEditsStore.emitChange();
    default:
      // no default
  }
});


export default RecentEditsStore;
