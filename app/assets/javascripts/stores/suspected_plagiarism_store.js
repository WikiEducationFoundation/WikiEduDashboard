import McFly from 'mcfly';
const Flux = new McFly();

const _revisions = [];

const setRevisions = function (data) {
  return data.revisions.map(revision => _revisions.push(revision));
};

const storeMethods = {
  empty() {
    return _revisions.length = 0;
  },
  getRevisions() {
    return _revisions;
  }
};

const SuspectedPlagiarismStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'RECEIVE_SUSPECTED_PLAGIARISM':
      SuspectedPlagiarismStore.empty();
      setRevisions(data);
      return SuspectedPlagiarismStore.emitChange();
    default:
      // no default
  }
});

export default SuspectedPlagiarismStore;
