const I18n = require('i18n-js');

const CourseUtils = class {
  generateTempId(course) {
    const title = this.slugify(course.title.trim());
    const school = this.slugify(course.school.trim());
    let term = '';
    let slug = `${school}/${title}`;
    if (course.term !== null && typeof course.term !== 'undefined') {
      term = this.slugify(course.term.trim());
      slug = `${slug}_(${term})`;
    }
    return slug;
  }
  slugify(text) {
    if (typeof text !== 'undefined' && text !== null) {
      return text.split(' ').join('_');
    }
  }
  cleanupCourseSlugComponents(course) {
    const cleanedCourse = course;
    cleanedCourse.title = course.title.trim();
    cleanedCourse.school = course.school.trim();
    cleanedCourse.term = course.term.trim();
    return cleanedCourse;
  }

  // This builds i18n interface strings that vary based on state/props.
  i18n(messageKey, prefix, defaultPrefix = 'courses') {
    return I18n.t(`${prefix}.${messageKey}`, {
      defaults: [{ scope: `${defaultPrefix}.${messageKey}` }]
    });
  }
};

export default new CourseUtils();
