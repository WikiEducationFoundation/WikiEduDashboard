const I18n = require('i18n-js');

const CourseUtils = class {
  generateTempId(course) {
    const title = this.slugify(course.title.trim());
    const school = this.slugify(course.school.trim());
    let term = '';
    let slug = `${school}/${title}`;
    if (course.term) {
      term = this.slugify(course.term.trim());
      slug = `${slug}_(${term})`;
    }
    return slug;
  }
  slugify(text) {
    if (typeof text !== 'undefined' && text !== null) {
      return text.split(/\s/).join('_');
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
    const articleTitle = articleTitleInput;
    if (!/http/.test(articleTitle)) {
      const title = articleTitle.replace(/_/g, ' ');
      return {
        title,
        project: null,
        language: null,
        // TODO: use the course home language and project to construct the url
        article_url: null
      };
    }

    const urlParts = /([a-z-]+)\.(wik[a-z]+)\.org\/wiki\/([^#]*)/.exec(articleTitle);
    if (urlParts && urlParts.length > 3) {
      const title = decodeURIComponent(urlParts[3]).replace(/_/g, ' ');
      const project = urlParts[2];
      const language = urlParts[1];
      return {
        title,
        project,
        language,
        article_url: articleTitle
      };
    }

    return {
      title: articleTitleInput,
      project: null,
      language: null
    };
  }

  articleFromAssignment(assignment) {
    const language = assignment.language || 'en';
    const project = assignment.project || 'wikipedia';
    const articleUrl = assignment.article_url || this.urlFromTitleAndWiki(assignment.article_title, language, project);
    const formattedTitle = this.formattedArticleTitle(
      language,
      project,
      assignment.article_title
    );
    const article = {
      rating: assignment.article_rating,
      rating_num: assignment.article_rating_num,
      pretty_rating: assignment.article_pretty_rating,
      url: articleUrl,
      title: assignment.article_title,
      formatted_title: formattedTitle,
      language,
      project,
      new: false
    };
    return article;
  }

  urlFromTitleAndWiki(title, language, project) {
    const underscoredTitle = title.replace(/ /g, '_');
    return `https://${language}.${project}.org/wiki/${underscoredTitle}`;
  }

  formattedArticleTitle(language, project, articleTitle) {
    let languagePrefix = '';
    if (language === undefined || language === 'en') {
      languagePrefix = '';
    } else {
      languagePrefix = `${language}:`;
    }

    let projectPrefix = '';
    if (project === undefined || project === 'wikipedia') {
      projectPrefix = '';
    } else {
      projectPrefix = `${project}:`;
    }

    return `${languagePrefix}${projectPrefix}${articleTitle}`;
  }

  hasTrainings(weeks) {
    function blockHasTrainings(block) {
      return Boolean(block.training_module_ids && block.training_module_ids.length);
    }
    function weekHasTrainings(week) {
      if (!week.blocks.length) { return false; }
      return Boolean(_.find(week.blocks, blockHasTrainings));
    }
    if (!weeks.length) { return false; }
    return Boolean(_.find(weeks, weekHasTrainings));
  }
};

export default new CourseUtils();
