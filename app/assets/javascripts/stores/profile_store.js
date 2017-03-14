import McFly from 'mcfly';  // library that provides all 3 components of Flux architecture
const Flux = new McFly(); // When McFly is instantiated, a single dispatcher instance is created

let _stats = null;
// createStore => helper method that creates an instance of a Store
const ProfileStore = Flux.createStore({
  getStats() {
    return _stats;
  } }, (payload) => {
  if (payload.actionType === "RECEIVE_STATISTICS") {
    _stats = payload.data;
    ProfileStore.emitChange();
  }
});

export default ProfileStore;
