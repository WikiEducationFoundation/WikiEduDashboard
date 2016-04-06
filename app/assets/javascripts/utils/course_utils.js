class CourseUtils {
  generateTempId(course) {
    const title = this.slugify(course.title.trim());
    const school = this.slugify(course.school.trim());
    let term = '';
    let slug = `${school}/${title}`;
    if (course.term !== null && typeof course.term !== 'undefined') {
      term = this.slugify(course.term.trim());
      slug = `${slug}_${term}`;
    }
    return slug;
  }
}

export default CourseUtils;
