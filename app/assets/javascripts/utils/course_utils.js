import _ from 'lodash';

export default class CourseUtils {
  // Given a course object with title, school and term properties,
  // generate the standard 'slug' that is used as the course URL.
  static generateTempId(course) {
    const title = CourseUtils.slugify(course.title.trim());
    const school = CourseUtils.slugify(course.school.trim());
    let term = '';
    let slug = `${school}/${title}`;
    if (course.term) {
      term = CourseUtils.slugify(course.term.trim());
      slug = `${slug}_(${term})`;
    }
    return slug;
  }

  static slugify(text) {
    if (typeof text !== 'undefined' && text !== null) {
      return text.split(/\s+/).join('_');
    }
  }

  // Regex of allowed characters for a course slug.
  static courseSlugRegex() {
  // This regex is intended to match ascii word characters, dash,
  // whitespace, comma, apostrophe, and any unicode "letter".
  // It requires blank spaces(if any) in the beginning to be followed by at least one non-blank letter character
  // from the allowed characters, to be followed by zero or more of all allowed characters(including blank characters).
  // Adapted from http://stackoverflow.com/questions/150033/regular-expression-to-match-non-english-characters#comment19644791_150078
    return /^[\w\-\s,'\u00BF-\u1FFF\u2C00-\uD7FF]*[\w\u00BF-\u1FFF\u2C00-\uD7FF][\w\-\s,'\u00BF-\u1FFF\u2C00-\uD7FF]*$/;
  }

  // Given a course object with title, school and term properties,
  // return a new course object with sanitized versions of those properties,
  // in particular by removing excess whitespace.
  static cleanupCourseSlugComponents(course) {
    const cleanedCourse = { ...course };
    cleanedCourse.title = course.title.trim().split(/\s+/).join(' ');
    cleanedCourse.school = course.school.trim().split(/\s+/).join(' ');
    cleanedCourse.term = course.term.trim().split(/\s+/).join(' ');
    return cleanedCourse;
  }

  // This builds i18n interface strings that vary based on state/props.
  static i18n(messageKey, prefix, defaultPrefix = 'courses') {
    return I18n.t(`${prefix}.${messageKey}`, {
      defaults: [{ scope: `${defaultPrefix}.${messageKey}` }]
    });
  }

  // Takes user input — either a URL or the title of an article —
  // and returns an article object, including the project and language
  // if that can be pattern matched from URL input.
  static articleFromTitleInput(articleTitleInput) {
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

    const urlParts = /([a-z-]+)\.(?:m\.)?(wik[a-z]+)\.org\/wiki\/([^#]*)/.exec(articleTitle);
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

    const wikisourceUrlParts = /wikisource\.org\/wiki\/([^#]*)/.exec(articleTitle);
    if (wikisourceUrlParts) {
      const title = decodeURIComponent(wikisourceUrlParts[1]).replace(/_/g, ' ');
      const project = 'wikisource';
      const language = 'www';
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

  // Given an assignment object and a wiki object,
  // return a corresponding article object
  static articleFromAssignment(assignment, defaultWiki) {
    const language = assignment.language || defaultWiki.language || 'en';
    const project = assignment.project || defaultWiki.project || 'wikipedia';
    const articleUrl = assignment.article_url || this.urlFromTitleAndWiki(assignment.article_title, language, project);
    const article = {
      rating: assignment.article_rating,
      rating_num: assignment.article_rating_num,
      pretty_rating: assignment.article_pretty_rating,
      url: articleUrl,
      title: assignment.article_title,
      article_id: assignment.article_id,
      language,
      project,
      new: false
    };
    article.formatted_title = this.formattedArticleTitle(article, defaultWiki);
    return article;
  }

  // Return the MediaWiki page URL, given title, language, and project.
  static urlFromTitleAndWiki(title, language, project) {
    const underscoredTitle = title.replace(/ /g, '_');
    return `https://${language}.${project}.org/wiki/${underscoredTitle}`;
  }

  // Construct the best possible human-readable title for an article.
  // This means showing the language and/or project if it's not the
  // default one.
  static formattedArticleTitle(article, defaultWiki, wikidataLabel) {
    let languagePrefix = '';
    if (!defaultWiki || !article.language || article.language === defaultWiki.language) {
      languagePrefix = '';
    } else {
      languagePrefix = `${article.language}:`;
    }

    let projectPrefix = '';
    if (!defaultWiki || article.project === defaultWiki.project || !article.project) {
      projectPrefix = '';
    } else {
      projectPrefix = `${article.project}:`;
    }

    let title = article.title;
    if (article.project === 'wikidata' && wikidataLabel) {
      title = wikidataLabel;
    }
    return `${languagePrefix}${projectPrefix}${title}`;
  }

  static formattedCategoryName(category, defaultWiki) {
    category.title = category.name;
    category.language = category.wiki.language;
    category.project = category.wiki.project;
    return this.formattedArticleTitle(category, defaultWiki);
  }

  // Given an array of weeks (ie, a timeline), return true if the timeline
  // includes any training modules.
  static hasTrainings(weeks) {
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

  // Is the location the main index of a course page, rather than one of the
  // tabs?
  static onCourseIndex(location) {
    return location.pathname.split('/').length === 4;
  }

  static onHomeTab(location) {
    if (this.onCourseIndex(location)) { return true; }
    return location.pathname.substr(-5) === '/home';
  }

  static newCourseStats(oldCourse, newCourse) {
    return {
      created_count: oldCourse.created_count !== newCourse.created_count,
      edited_count: oldCourse.edited_count !== newCourse.edited_count,
      edit_count: oldCourse.edit_count !== newCourse.edit_count,
      student_count: oldCourse.student_count !== newCourse.student_count,
      word_count: oldCourse.character_sum_human !== newCourse.character_sum_human,
      view_count: oldCourse.view_count !== newCourse.view_count,
      upload_count: oldCourse.upload_count !== newCourse.upload_count,
      requestedAccounts: oldCourse.requestedAccounts !== newCourse.requestedAccounts
    };
  }

  // Given a course and camelized stats from the above `newCourseStats`
  // function, return only the key-value pairs of what needs to be updated
  // in the course.
  static courseStatsToUpdate(course, newStats) {
    return Object.entries(newStats)
      .filter(([, val]) => val)
      .reduce((acc, [key]) => ({ ...acc, [key]: course[key] }), {});
  }

  // This method is used to format the onboarding alert message which
  // starts as a block of text that could look like the following:
  // 'HEARD FROM:\nassociation (name)\n\nWHY HERE:\nteach this term\n\nOTHER:\n\n'
  // By the end of 2019, we should hopefully be able to remove this method
  // assuming messages are now serialized as a hash in the DB.
  static formatOnboardingAlertMessage(message) {
    // Split on main categories and remove an empy array position that will
    // appear at the very end.
    // e.g. [ 'HEARD FROM:\nassociation (name)', 'WHY HERE:\nteach', ... ]
    const categories = message.split('\n\n').slice(0, -1);
    return categories.map((category) => {
      // Grab the content after the category heading
      const [, content] = category.split(':');
      // If there is content, return it, otherwise return N/A
      return content.trim() ? category : `${category.trim()}\nN/A`;
    });
  }
}
