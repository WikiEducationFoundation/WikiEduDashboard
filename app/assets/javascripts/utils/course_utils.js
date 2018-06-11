import _ from 'lodash';
const I18n = require('i18n-js');

const CourseUtils = class {
  // Given a course object with title, school and term properties,
  // generate the standard 'slug' that is used as the course URL.
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
      return text.split(/\s+/).join('_');
    }
  }

  // Regex of allowed characters for a course slug.
  courseSlugRegex() {
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
  cleanupCourseSlugComponents(course) {
    const cleanedCourse = { ...course };
    cleanedCourse.title = course.title.trim().split(/\s+/).join(' ');
    cleanedCourse.school = course.school.trim().split(/\s+/).join(' ');
    cleanedCourse.term = course.term.trim().split(/\s+/).join(' ');
    return cleanedCourse;
  }

  // This builds i18n interface strings that vary based on state/props.
  i18n(messageKey, prefix, defaultPrefix = 'courses') {
    return I18n.t(`${prefix}.${messageKey}`, {
      defaults: [{ scope: `${defaultPrefix}.${messageKey}` }]
    });
  }

  // Takes user input — either a URL or the title of an article —
  // and returns an article object, including the project and language
  // if that can be pattern matched from URL input.
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
  articleFromAssignment(assignment, defaultWiki) {
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
  urlFromTitleAndWiki(title, language, project) {
    const underscoredTitle = title.replace(/ /g, '_');
    return `https://${language}.${project}.org/wiki/${underscoredTitle}`;
  }

  // Construct the best possible human-readable title for an article.
  // This means showing the language and/or project if it's not the
  // default one.
  formattedArticleTitle(article, defaultWiki, wikidataLabel) {
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

  formattedCategoryName(category, defaultWiki) {
    category.title = category.name;
    category.language = category.wiki.language;
    category.project = category.wiki.project;
    return this.formattedArticleTitle(category, defaultWiki);
  }

  // Given an array of weeks (ie, a timeline), return true if the timeline
  // includes any training modules.
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

  // Is the location the main index of a course page, rather than one of the
  // tabs?
  onCourseIndex(location) {
    return location.pathname.split('/').length === 4;
  }
};

export default new CourseUtils();
