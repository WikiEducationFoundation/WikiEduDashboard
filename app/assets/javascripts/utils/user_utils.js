const UserUtils = class {
  userRoles(currentUser, userStore) {
    // Role values correspond to the CoursesUsers roles defined
    const roles = {};
    if (!currentUser) { return roles; }
    if (userStore.getFiltered({ id: currentUser.id, role: 0 })[0]) {
      roles.isStudent = true;
      roles.isEnrolled = true;
    }
    if (userStore.getFiltered({ id: currentUser.id, role: 1 })[0]) {
      roles.isInstructor = true;
      roles.isNonstudent = true;
      roles.isEnrolled = true;
    }
    if (userStore.getFiltered({ id: currentUser.id, role: 2 })[0]) {
      roles.isCampusVolunteer = true;
      roles.isNonstudent = true;
      roles.isEnrolled = true;
    }
    if (userStore.getFiltered({ id: currentUser.id, role: 3 })[0]) {
      roles.isOnlineVolunteer = true;
      roles.isNonstudent = true;
      roles.isEnrolled = true;
    }
    if (userStore.getFiltered({ id: currentUser.id, role: 4 })[0]) {
      roles.isStaff = true;
      roles.isNonstudent = true;
      roles.isEnrolled = true;
    }
    if (!roles.isEnrolled) {
      roles.notEnrolled = true;
    }
    if (currentUser.admin) {
      roles.isAdmin = true;
      roles.isNonstudent = true;
    }
    return roles;
  }

  userTalkUrl(username, language, project) {
    return `https://${language}.${project}.org/wiki/User_talk:${username}`;
  }
};

export default new UserUtils();
