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

  articleFromTitleInput(articleTitleInput) {
    const articleTitle = articleTitleInput.trim();
    if (!/http/.test(articleTitle)) {
      const title = articleTitle.replace(/_/g, ' ');
      return {
        title,
        project: null,
        language: null
      };
    }

    const urlParts = /([a-z-]+)\.(wiki[a-z]+)\.org\/wiki\/([^#]*)/.exec(articleTitle);
    if (urlParts.length > 3) {
      const title = decodeURIComponent(urlParts[3]).replace(/_/g, ' ');
      const project = urlParts[2];
      const language = urlParts[1];
      return {
        title,
        project,
        language
      };
    }

    return null;
  }

  articleFromAssignment(assignment) {
    const languagePrefix = assignment.language ? `${assignment.language}:` : '';
    const projectName = assignment.project || 'wikipedia';
    const projectPrefix = projectName === 'wikipedia' ? '' : `${projectName}:`;
    const formattedTitle = `${languagePrefix}${projectPrefix}${assignment.article_title}`;
    const article = {
      rating_num: null,
      pretty_rating: null,
      url: assignment.article_url,
      language: assignment.language,
      project: projectName,
      title: assignment.article_title,
      formatted_title: formattedTitle,
      new: false
    };
    return article;
  }
};

export default new CourseUtils();
