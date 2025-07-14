import '../testHelper';
import courseUtils from '../../app/assets/javascripts/utils/course_utils.js';

describe('courseUtils.generateTempId', () => {
  test('creates a slug from term, title and school', () => {
    const course = {
      term: 'Fall 2015',
      school: 'University of Wikipedia',
      title: 'Introduction to Editing'
    };
    const slug = courseUtils.generateTempId(course);
    expect(slug).toBe('University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)');
  });

  test('trims unnecessary whitespace', () => {
    const course = {
      term: ' Fall 2015',
      school: '   University of Wikipedia ', // includes a non-breaking space
      title: ' Introduction to Editing     '
    };
    const slug = courseUtils.generateTempId(course);
    expect(slug).toBe('University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)');
  });

  test('collapses multiple whiltespaces into one space', () => {
    const course = {
      term: 'Fall    2015',
      school: ' University    of   Wikipedia            ',
      title: '          Introduction     to         Editing          '
    };
    const slug = courseUtils.generateTempId(course);
    expect(slug).toBe('University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)');
  });

  test('creates a slug from title and school when term is empty', () => {
    const course = {
      school: ' University of Wikipedia',
      title: 'Introduction to Editing'
    };
    const slug = courseUtils.generateTempId(course);
    expect(slug).toBe('University_of_Wikipedia/Introduction_to_Editing');
  });
});

describe('CourseUtils.courseSlugRegex', () => {
  test('returns a regex that validates course slug', () => {
    const courseSlugRegex = courseUtils.courseSlugRegex();
    expect(courseSlugRegex.test(' 維基醫學專案 ')).toBe(true);
    expect(courseSlugRegex.test(' North-Cap University')).toBe(true);
    expect(courseSlugRegex.test(' مركز حملة')).toBe(true);
    expect(courseSlugRegex.test('UW, Bothell')).toBe(true);
    expect(courseSlugRegex.test('वसंत 2017')).toBe(true);
    expect(courseSlugRegex.test('  ')).toBe(false);
    expect(courseSlugRegex.test('')).toBe(false);
    expect(courseSlugRegex.test('Washington University in St. Louis')).toBe(true);
  });
});

describe('courseUtils.cleanupCourseSlugComponents', () => {
  test(
    'trims whitespace and collapses multispaces from the slug-related fields of a course object',
    () => {
      const course = {
        term: ' Fall      2015',
        school: '   University          of       Wikipedia ',
        title: '   Introduction      to      Editing     '
      };
      const cleanedCourse = courseUtils.cleanupCourseSlugComponents(course);
      expect(cleanedCourse.term).toBe('Fall 2015');
      expect(cleanedCourse.school).toBe('University of Wikipedia');
      expect(cleanedCourse.title).toBe('Introduction to Editing');
    }
  );
});

describe('courseUtils.i18n', () => {
  test('outputs an interface message based on a message key and prefix', () => {
    const message = courseUtils.i18n('students', 'courses_generic');
    expect(message).toBe('Editors');
  });

  test('defaults to the "courses" prefix if prefix is null', () => {
    const message = courseUtils.i18n('students', null);
    expect(message).toBe('Students');
  });

  test('takes an optional fallback prefix for if prefix is null', () => {
    const message = courseUtils.i18n('class', null, 'revisions');
    expect(message).toBe('Class');
  });
});

describe('courseUtils.articleFromTitleInput', () => {
  test('replaces underscores', () => {
    const input = 'Robot_selfie';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Robot selfie');
  });

  test('converts Wikipedia urls into titles', () => {
    const input = 'https://en.wikipedia.org/wiki/Robot_selfie';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Robot selfie');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe(input);
  });

  test('handles mobile urls correctly', () => {
    const input = 'https://en.m.wikipedia.org/wiki/Robot_selfie';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Robot selfie');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe(input);
  });

  test("correctly parses multilingual wikisource url's", () => {
    const input = 'https://wikisource.org/wiki/Heyder_Cansa';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Heyder Cansa');
    expect(output.project).toBe('wikisource');
    expect(output.language).toBe('www');
    expect(output.article_url).toBe(input);
  });

  test('correctly parses the wikimedia incubator url', () => {
    const input = 'https://incubator.wikimedia.org/wiki/Wp/kiu/Heyder_Cansa';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Wp/kiu/Heyder Cansa');
    expect(output.project).toBe('wikimedia');
    expect(output.language).toBe('incubator');
    expect(output.article_url).toBe(input);
  });

  test('handles url-encoded characters in Wikipedia urls', () => {
    const input = 'https://es.wikipedia.org/wiki/Jalape%C3%B1o';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Jalapeño');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('es');
    expect(output.article_url).toBe(input);
  });

  test('correctly parses Wikipedia redlinks', () => {
    const input = 'https://en.wikipedia.org/w/index.php?title=Redlink&action=edit&redlink=1';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Redlink');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe(input);
  });

  test('correctly parses wikipedia redlinks (variation: The edit link for an older revision)', () => {
    const input = 'https://en.wikipedia.org/w/index.php?title=72nd_Primetime_Emmy_Awards&oldid=980777920&action=edit';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('72nd Primetime Emmy Awards');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe(input);
  });

  test('correctly parses wikipedia redlinks (variation: Section edit link)', () => {
    const input = 'https://en.wikipedia.org/w/index.php?title=Sweetwater_Formation&action=edit&section=2';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Sweetwater Formation');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe(input);
  });

  test('correctly parses wikipedia redlinks (variation: Old version of page)', () => {
    const input = 'https://en.wikipedia.org/w/index.php?title=Smedsb%C3%B6le_Radio_Mast&oldid=479392613';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Smedsböle Radio Mast');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe(input);
  });

  test('correctly parses wikipedia redlinks (variation: Old version edit link using VisualEditor)', () => {
    const input = ' https://en.wikipedia.org/w/index.php?title=Christian_Social_Party_of_Obwalden&oldid=886780353&veaction=editsource';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Christian Social Party of Obwalden');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe(input);
  });

  test('correctly parses mobile Wikipedia redlinks', () => {
    const input = 'https://en.m.wikipedia.org/w/index.php?title=Red_link&action=edit&redlink=1';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Red link');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe(input);
  });

  test('correctly parses Wikimedia redlinks', () => {
    const input = 'https://incubator.wikimedia.org/w/index.php?title=Redlink&action=edit&redlink=1';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Redlink');
    expect(output.project).toBe('wikimedia');
    expect(output.language).toBe('incubator');
    expect(output.article_url).toBe(input);
  });

  test('handles url-encoded characters in Wikipedia redlinks -- #1', () => {
    const input = 'https://en.wikipedia.org/w/index.php?title=Jalape%C3%B1o&action=edit&redlink=1';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Jalapeño');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe(input);
  });

  test('handles url-encoded characters in Wikipedia redlinks -- #2', () => {
    const input = 'https://en.wikipedia.org/w/index.php?title=Mesut%20%C3%96zil:REDLINK&redirect=no';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).toBe('Mesut Özil');
    expect(output.project).toBe('wikipedia');
    expect(output.language).toBe('en');
    expect(output.article_url).toBe('https://en.wikipedia.org/wiki/Mesut%20%C3%96zil:REDLINK');
  });
});

describe('courseUtils.articleFromAssignment', () => {
  test(
    'returns an article object with the language, project, title, and url',
    () => {
      const assignment = {
        article_url: 'https://es.wikipedia.org/wiki/Autofoto',
        language: 'es',
        article_title: 'Autofoto',
        project: 'wikipedia'
      };
      const defaultWiki = {
        language: 'es',
        project: 'wikipedia'
      };
      const article = courseUtils.articleFromAssignment(assignment, defaultWiki);
      expect(article.url).toBe('https://es.wikipedia.org/wiki/Autofoto');
      expect(article.title).toBe('Autofoto');
      expect(article.language).toBe('es');
      expect(article.formatted_title).toBe('Autofoto');
    }
  );

  test(
    'returns an article object with the language, project, title, and url, comparing it to the default wiki',
    () => {
      const assignment = {
        article_url: 'https://es.wikipedia.org/wiki/Silvia_Federici',
        language: 'es',
        article_title: 'Silvia Federici',
        project: 'wikipedia'
      };
      const defaultWiki = {
        language: 'en',
        project: 'wikipedia'
      };
      const article = courseUtils.articleFromAssignment(assignment, defaultWiki);
      expect(article.url).toBe('https://es.wikipedia.org/wiki/Silvia_Federici');
      expect(article.title).toBe('Silvia Federici');
      expect(article.language).toBe('es');
      expect(article.formatted_title).toBe('es:Silvia Federici');
    }
  );

  test(
    'returns an article object with the language of the default wiki if no langaue is set',
    () => {
      const assignment = {
        article_url: 'https://es.wikipedia.org/wiki/Silvia_Federici',
        article_title: 'Silvia Federici',
        project: 'wikipedia'
      };
      const defaultWiki = {
        language: 'es',
        project: 'wikipedia'
      };
      const article = courseUtils.articleFromAssignment(assignment, defaultWiki);
      expect(article.url).toBe('https://es.wikipedia.org/wiki/Silvia_Federici');
      expect(article.title).toBe('Silvia Federici');
      expect(article.language).toBe('es');
      expect(article.formatted_title).toBe('Silvia Federici');
    }
  );

  test('sets wikipedia as the default project', () => {
    const assignment = {
      article_url: 'https://en.wikipedia.org/wiki/Selfie',
      article_title: 'Selfie'
    };
    const defaultWiki = {
      language: 'en'
    };
    const article = courseUtils.articleFromAssignment(assignment, defaultWiki);
    expect(article.project).toBe('wikipedia');
  });

  test('constructs a url if one is not included', () => {
    const assignment = {
      article_title: 'Palo para autofoto',
      language: 'es',
      project: 'wikipedia'
    };
    const defaultWiki = {
      language: 'en',
      project: 'wikipedia'
    };
    const article = courseUtils.articleFromAssignment(assignment, defaultWiki);
    expect(article.url).toBe('https://es.wikipedia.org/wiki/Palo_para_autofoto');
  });
});

describe('courseUtils.hasTrainings', () => {
  test('returns false for a weeks array with no trainings', () => {
    const weeks = [{ blocks: [{ training_module_ids: [] }, { training_module_ids: [] }] }];
    const output = courseUtils.hasTrainings(weeks);
    expect(output).toBe(false);
  });

  test('returns true for a weeks array with trainings', () => {
    const weeks = [{ blocks: [{ training_module_ids: [] }, { training_module_ids: [1] }] }];
    const output = courseUtils.hasTrainings(weeks);
    expect(output).toBe(true);
  });
});

describe('courseUtils.formattedArticleTitle', () => {
  test(
    'returns a formatted_article from the same project and language in article and defaultWiki',
    () => {
      const defaultWiki = {
        language: 'en',
        project: 'wikipedia'
      };
      const article = {
        title: 'Riot Grrrl',
        language: 'en',
        project: 'wikipedia'
      };
      article.formatted_title = courseUtils.formattedArticleTitle(article, defaultWiki);
      expect(article.formatted_title).toBe('Riot Grrrl');
    }
  );

  test(
    'returns a formatted_article from same project different language',
    () => {
      const defaultWiki = {
        language: 'en',
        project: 'wikipedia'
      };
      const article = {
        title: 'Virgine Despentes',
        language: 'fr',
        project: 'wikipedia'
      };
      article.formatted_title = courseUtils.formattedArticleTitle(article, defaultWiki);
      expect(article.formatted_title).toBe('fr:Virgine Despentes');
    }
  );

  test('returns a formatted_article from diferent project same language', () => {
    const defaultWiki = {
      language: 'en',
      project: 'wikipedia'
    };
    const article = {
      title: 'Virginia Woolf',
      language: 'en',
      project: 'wikiquote'
    };
    article.formatted_title = courseUtils.formattedArticleTitle(article, defaultWiki);
    expect(article.formatted_title).toBe('wikiquote:Virginia Woolf');
  });

  test(
    'returns a formatted_article from diferent project different language',
    () => {
      const defaultWiki = {
        language: 'en',
        project: 'wikipedia'
      };
      const article = {
        title: 'Clara Campoamor',
        language: 'es',
        project: 'wikiquote'
      };
      article.formatted_title = courseUtils.formattedArticleTitle(article, defaultWiki);
      expect(article.formatted_title).toBe('es:wikiquote:Clara Campoamor');
    }
  );

  test(
    'returns a formatted_article from diferent project and no language',
    () => {
      const defaultWiki = {
        language: 'en',
        project: 'wikipedia'
      };
      const article = {
        title: 'Judith Butler',
        language: null,
        project: 'wikidata'
      };
      article.formatted_title = courseUtils.formattedArticleTitle(article, defaultWiki);
      expect(article.formatted_title).toBe('wikidata:Judith Butler');
    }
  );

  describe('courseUtils.courseStatsToUpdate', () => {
    const course = {
      title: 'My Course',
      description: 'My Description',
      student_count: 0,
      upload_count: 0
    };

    const stats = {
      student_count: false,
      upload_count: false
    };

    test('should return an empty object if no stats should be updated', () => {
      const actual = courseUtils.courseStatsToUpdate(course, stats);
      const expected = {};
      expect(actual).toEqual(expected);
    });

    test(
      'should return key-value pairs of what stats to update in a course',
      () => {
        const courseData = { ...course, student_count: 99 };
        const newStats = { ...stats, student_count: true };

        const actual = courseUtils.courseStatsToUpdate(courseData, newStats);
        const expected = { student_count: 99 };
        expect(actual).toEqual(expected);
      }
    );
  });
});
