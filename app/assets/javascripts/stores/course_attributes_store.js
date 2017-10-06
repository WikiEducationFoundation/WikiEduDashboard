let defaultCourseType;
let courseStringPrefix;
let useStartAndEndTimes;

export function setDefaultCourseType(courseType) {
  defaultCourseType = courseType;
}

export function getDefaultCourseType() {
  return defaultCourseType;
}

export function setCourseStringPrefix(prefix) {
  courseStringPrefix = prefix;
}

export function getCourseStringPrefix() {
  return courseStringPrefix;
}

export function setUseStartAndEndTimes(value) {
  useStartAndEndTimes = value;
}

export function getUseStartAndEndTimes() {
  return useStartAndEndTimes;
}
