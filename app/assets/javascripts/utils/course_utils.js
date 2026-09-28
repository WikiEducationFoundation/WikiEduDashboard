import { safeDecodeURIComponent } from './strings';
import { find } from 'lodash-es';
import ArrayUtils from './array_utils';

export default class CourseUtils {
  // Given a course object with title, school and term properties,
  // generate the standard 'slug' that is used as the course URL.
  static generateTempId(course) {
    if (course.school === '' || course.title === '') return '';
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
    // Matches:
    // - Unicode letters (\p{L}), combining marks (\p{M}), numbers (\p{N}),
    //   ASCII word characters (\w), and Unicode dashes (\p{Pd})
    // - Whitespace (\s)
    // - Zero-width non-joiner (\u200C) and zero-width joiner (\u200D) for complex scripts
    // - Script commas: ASCII comma, Arabic comma (\u060C), Arabic date separator (\u066C),
    //   Armenian comma (\u055D), NKo comma (\u07F8), Myanmar comma (\u104A), Ethiopic comma (\u1363),
    //   Mongolian commas (\u1802, \u1808), ideographic comma (\u3001), fullwidth comma (\uFF0C),
    //   and Lisu / Vai / Saurashtra commas (\uA4FE, \uA60D, \uA6F5)
    // - Script apostrophes / single quotes: ASCII apostrophe, single quotes (\u2018, \u2019),
    //   Hebrew geresh and gershayim (\u05F3, \u05F4), Armenian apostrophe and modifier letter (\u055A, \u055F)
    // - Script word/syllable separators: middle dots (\u00B7, \u30FB, \u2E31), Tibetan tsheg (\u0F0B, \u0F0C),
    //   Ethiopic wordspace (\u1361), and Mongolian separators (\u1807, \u180A)
    // The middle group [\p{L}\p{N}\w] ensures at least one letter or number is present.
    // The trailing group also permits periods and script full stops (preventing leading periods):
    // - ASCII period, Arabic full stop (\u06D4), Arabic decimal separator (\u066B),
    //   Armenian full stop (\u0589), Devanagari danda and double danda (\u0964, \u0965),
    //   Devanagari abbreviation signs (\u0970, \u09FD), Gurmukhi / Gujarati / Sinhala / Tibetan
    //   sentence marks (\u0A76, \u0AF0, \u0DF4, \u0F0D), Myanmar period (\u104B),
    //   Ethiopic full stop (\u1362), Canadian syllabics full stop (\u166E), Khmer sign khan (\u17D4),
    //   Mongolian full stops (\u1803, \u1809), ideographic full stop (\u3002), fullwidth full stop (\uFF0E),
    //   and Lisu / Vai / Saurashtra / Kayah Li full stops (\uA4FF, \uA60E, \uA6F3, \uA8CE, \uA8CF, \uAA5D)
    // eslint-disable-next-line no-misleading-character-class
    return /^[\p{L}\p{M}\p{N}\w\p{Pd}\s\u200C\u200D,\u060C\u066C\u055D\u07F8\u104A\u1363\u1802\u1808\u3001\uFF0C\uA4FE\uA60D\uA6F5'\u2018\u2019\u05F3\u05F4\u055A\u055F\u00B7\u30FB\u0F0B\u0F0C\u1361\u1807\u180A\u2E31]*[\p{L}\p{N}\w][\p{L}\p{M}\p{N}\w\p{Pd}\s\u200C\u200D,\u060C\u066C\u055D\u07F8\u104A\u1363\u1802\u1808\u3001\uFF0C\uA4FE\uA60D\uA6F5'\u2018\u2019\u05F3\u05F4\u055A\u055F\u00B7\u30FB\u0F0B\u0F0C\u1361\u1807\u180A\u2E31.\u06D4\u066B\u0589\u0964\u0965\u0970\u09FD\u0A76\u0AF0\u0DF4\u0F0D\u104B\u1362\u166E\u17D4\u1803\u1809\u3002\uFF0E\uA4FF\uA60E\uA6F3\uA8CE\uA8CF\uAA5D]*$/u;
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
    if (typeof articleTitleInput !== 'string') { return { title: '', project: null, language: null }; }
    const articleTitle = articleTitleInput.trim();
    if (!/http/.test(articleTitle)) {
      // Check for interwiki prefix format (e.g., 'en:Article' or 'wikt:fr:Word')
      // Strip an optional leading colon
      let normalizedInput = articleTitle.trim();
      if (normalizedInput.startsWith(':')) {
        normalizedInput = normalizedInput.slice(1);
      }

      const parts = normalizedInput.split(':');
      if (parts.length >= 2) {
        const prefix1 = parts[0].toLowerCase();
        let project = null;
        let language = null;
        let title = null;

        const projectMappings = {
          w: 'wikipedia',
          wikt: 'wiktionary',
          q: 'wikiquote',
          b: 'wikibooks',
          n: 'wikinews',
          s: 'wikisource',
          v: 'wikiversity',
          voy: 'wikivoyage',
          c: 'wikimedia',
          m: 'wikimedia'
        };

        const languages = WikiLanguages ? JSON.parse(WikiLanguages) : [];
        const projects = WikiProjects ? JSON.parse(WikiProjects) : [];

        const mappedOrRealProject = projectMappings[prefix1] || (projects.includes(prefix1) ? prefix1 : null);

        // Special case for Meta and Commons shorthands
        if (prefix1 === 'm') {
          project = 'wikimedia';
          language = 'meta';
          title = parts.slice(1).join(':');
        } else if (prefix1 === 'c') {
          project = 'wikimedia';
          language = 'commons';
          title = parts.slice(1).join(':');
        } else if (mappedOrRealProject) {
          project = mappedOrRealProject;
          // Check for language in next part
          if (parts.length >= 3 && languages.includes(parts[1].toLowerCase())) {
            language = parts[1].toLowerCase();
            title = parts.slice(2).join(':');
          } else {
            title = parts.slice(1).join(':');
          }
        } else if (languages.includes(prefix1)) {
          language = prefix1;

          let prefix2 = null;
          if (parts.length >= 3) {
            prefix2 = parts[1].toLowerCase();
          }
          const mappedOrRealProject2 = prefix2 ? (projectMappings[prefix2] || (projects.includes(prefix2) ? prefix2 : null)) : null;

          if (mappedOrRealProject2) {
            project = mappedOrRealProject2;
            title = parts.slice(2).join(':');
          } else {
            project = 'wikipedia';
            title = parts.slice(1).join(':');
          }
        }

        if (project) {
          return {
            title: title.replace(/_/g, ' '),
            project,
            language,
            article_url: articleTitle
          };
        }
      }

      const title = articleTitle.replace(/_/g, ' ');
      return {
        title,
        project: null,
        language: null,
        article_url: null
      };
    }

    const urlParts = /([a-z-]+)\.(?:m\.)?(wik[a-z]+)\.org\/wiki\/([^#]*)/.exec(articleTitle);
    if (urlParts && urlParts.length > 3) {
      const title = safeDecodeURIComponent(urlParts[3]).replace(/_/g, ' ');
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

    const indexphpFormatUrlParts = /([a-z-]+)\.(?:m\.)?(wik[a-z]+)\.org\/w\/index\.php\?title=([\w%]*)[^a-zA-Z0-9%](?:[^#]*)/.exec(articleTitle);
    if (indexphpFormatUrlParts) {
      const title = decodeURIComponent(indexphpFormatUrlParts[3]).replace(/_/g, ' ');
      const project = indexphpFormatUrlParts[2];
      const language = indexphpFormatUrlParts[1];
      return {
        title,
        project,
        language,
        article_url: articleTitleInput,
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
    if (!defaultWiki || !defaultWiki.language || !article.language || article.language === defaultWiki.language) {
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

  static articleAndArticleTitle(assignment, course, wikidataLabels) {
    const article = this.articleFromTitleInput(assignment.article_url);
    const label = wikidataLabels[article.title.replace('www:wikidata', '')];
    const title = this.formattedArticleTitle(article, course.home_wiki, label);

    return { article, title };
  }

  static formattedCategoryName(category, defaultWiki) {
    category.title = category.cat_name;
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
      return Boolean(find(week.blocks, blockHasTrainings));
    }
    if (!weeks.length) { return false; }
    return Boolean(find(weeks, weekHasTrainings));
  }

  // Is the location the main index of a course page, rather than one of the
  // tabs?
  static onCourseIndex(location) {
    if (location.pathname.split('/').length === 4) { return true; }
    if (location.pathname.split('/').length === 5 && location.pathname.substr(-1) === '/') { return true; }
    return false;
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
      references_count: oldCourse.references_count !== newCourse.references_count,
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


  // Adds the home wiki if not present
  // and removes the obsolete prev_wiki.
  // wikis = [{ language, project }]
  // home_wiki and prev_wiki = { language, project }
  static normalizeWikis(wikis, home_wiki, prev_wiki = {}) {
    if (!ArrayUtils.hasObject(wikis, home_wiki)) {
      wikis.unshift(home_wiki);
    }
    wikis = ArrayUtils.removeObject(wikis, prev_wiki);
    return wikis;
  }

  static removeNamespace(title) {
    if (title.indexOf(':') !== -1) {
      return title.split(':')[1];
    }
    return title;
  }
}

// these keys are to be sorted in descending order on first click
// this is used in the various reducers to sort the courses based on a key
export const COURSE_SORT_DESCENDING = {
  recent_revision_count: true,
  word_count: true,
  references_count: true,
  view_sum: true,
  user_count: true,
  average_word_count: true,
  trained_count: true,
};
