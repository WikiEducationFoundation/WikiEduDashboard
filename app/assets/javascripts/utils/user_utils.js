import { getFiltered } from './model_utils';
import { STUDENT_ROLE, INSTRUCTOR_ROLE, CAMPUS_VOLUNTEER_ROLE, ONLINE_VOLUNTEER_ROLE, STAFF_ROLE } from '../constants/user_roles';

const UserUtils = class {
  userRoles(currentUser, users) {
    // Role values correspond to the CoursesUsers roles defined
    const roles = {};
    if (!currentUser) { return roles; }
    if (getFiltered(users, { id: currentUser.id, role: STUDENT_ROLE })[0]) {
      roles.isStudent = true;
      roles.isEnrolled = true;
    }
    if (getFiltered(users, { id: currentUser.id, role: INSTRUCTOR_ROLE })[0]) {
      roles.isInstructor = true;
      roles.isAdvancedRole = true;
      roles.isEnrolled = true;
    }
    if (getFiltered(users, { id: currentUser.id, role: CAMPUS_VOLUNTEER_ROLE })[0]) {
      roles.isCampusVolunteer = true;
      roles.isEnrolled = true;
    }
    if (getFiltered(users, { id: currentUser.id, role: ONLINE_VOLUNTEER_ROLE })[0]) {
      roles.isOnlineVolunteer = true;
      roles.isEnrolled = true;
    }
    if (getFiltered(users, { id: currentUser.id, role: STAFF_ROLE })[0]) {
      roles.isStaff = true;
      roles.isAdvancedRole = true;
      roles.isEnrolled = true;
    }
    if (!roles.isEnrolled) {
      roles.notEnrolled = true;
    }
    if (currentUser.admin) {
      roles.isAdmin = true;
      roles.isAdvancedRole = true;
    }
    if (currentUser.campaign_organizer) {
      roles.isAdvancedRole = true;
    }
    return roles;
  }

  userTalkUrl(username, language, project) {
    return `https://${language}.${project}.org/wiki/User_talk:${username}`;
  }
};

export default new UserUtils();
