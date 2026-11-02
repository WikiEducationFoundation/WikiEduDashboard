// "View as student" lets a course's instructors preview the course page as an
// enrolled student would see it. The Redux `viewAsStudent` flag drives the UI;
// this module mirrors it for the request layer, which has no store access, and
// remembers it per course for the rest of the browser tab's session.
//
// While it's on:
// - course and users data are requested with `view_as=student`, so the server
//   leaves out what only instructors receive (the passcode, real names, etc.)
// - writes are blocked, except for an instructor managing their own assigned
//   articles and reviews, which they can also do outside of student view.

let active = false;

export const isStudentViewActive = () => active;

export const setStudentViewActive = (value) => {
  active = value;
};

const storageKey = courseSlug => `viewAsStudent:${courseSlug}`;

export const readStoredStudentView = (courseSlug) => {
  try {
    return sessionStorage.getItem(storageKey(courseSlug)) === 'true';
  } catch (e) {
    return false;
  }
};

export const storeStudentView = (courseSlug, value) => {
  try {
    if (value) {
      sessionStorage.setItem(storageKey(courseSlug), 'true');
    } else {
      sessionStorage.removeItem(storageKey(courseSlug));
    }
  } catch (e) { /* sessionStorage unavailable */ }
};

export const STUDENT_VIEW_PARAM = 'view_as=student';

// Course data endpoints whose JSON depends on the viewer's role.
const VIEWER_DEPENDENT_ENDPOINTS = ['course', 'users'];

export const studentViewQuery = (endpoint) => {
  if (!active || !VIEWER_DEPENDENT_ENDPOINTS.includes(endpoint)) { return ''; }
  return `?${STUDENT_VIEW_PARAM}`;
};

const SAFE_METHODS = ['GET', 'HEAD'];

// Writes allowed in student view: adding, removing, and claiming assigned
// articles and reviews, the My Articles progress steps, and sandbox URLs.
const ALLOWED_WRITES = [
  { method: 'POST', path: /^\/assignments(\.json)?$/ },
  { method: 'DELETE', path: /^\/assignments\/\d+$/ },
  { method: 'PUT', path: /^\/assignments\/\d+\/claim$/ },
  { method: 'PATCH', path: /^\/assignments\/\d+\/status(\.json)?$/ },
  { method: 'PATCH', path: /^\/assignments\/\d+\/update_sandbox_url$/ },
  // The navbar's language picker, which isn't part of the course page.
  { method: 'POST', path: /^\/update_locale\/[^/]+$/ }
];

const isExternal = path => /^https?:/.test(path);

export const isBlockedInStudentView = (method, path) => {
  if (!active) { return false; }
  const verb = method.toUpperCase();
  if (SAFE_METHODS.includes(verb)) { return false; }
  // Requests to other sites don't act as the instructor on the Dashboard.
  if (isExternal(path)) { return false; }
  const pathname = path.split('?')[0];
  return !ALLOWED_WRITES.some(allowed => allowed.method === verb && allowed.path.test(pathname));
};
