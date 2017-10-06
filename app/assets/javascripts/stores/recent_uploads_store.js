import McFly from 'mcfly';
const Flux = new McFly();

const _uploads = [];

const setUploads = function (data) {
  data.uploads.map(upload => _uploads.push(upload));
};

const storeMethods = {
  empty() {
    return _uploads.length = 0;
  },
  getUploads() {
    return _uploads;
  }
};

const RecentUploadsStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'RECEIVE_RECENT_UPLOADS':
      RecentUploadsStore.empty();
      setUploads(data);
      return RecentUploadsStore.emitChange();
    default:
      // no default
  }
});


export default RecentUploadsStore;
