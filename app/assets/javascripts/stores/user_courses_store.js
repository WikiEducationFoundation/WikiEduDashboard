import McFly from 'mcfly';
const Flux = new McFly();

const _userCourses = [];

const setUserCourses = function (data) {
  return _.forEach(data.courses, course => _userCourses.push(course));
};

const storeMethods = {
  getUserCourses() {
    return _userCourses;
  }
};

const UserCoursesStore = Flux.createStore(storeMethods, (payload) => {
  const { data } = payload;
  switch (payload.actionType) {
    case 'RECEIVE_USER_COURSES':
      setUserCourses(data);
      return UserCoursesStore.emitChange();
    default:
      // no default
  }
});

export default UserCoursesStore;
