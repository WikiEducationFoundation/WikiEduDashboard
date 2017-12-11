import '../testHelper';
import courseUtils from '../../app/assets/javascripts/utils/course_utils.js';

describe('courseUtils.generateTempId', () => {
  it('creates a slug from term, title and school', () => {
    const course = {
      term: 'Fall 2015',
      school: 'University of Wikipedia',
      title: 'Introduction to Editing'
    };
    const slug = courseUtils.generateTempId(course);
    expect(slug).to.eq('University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)');
  });

  it('trims unnecessary whitespace', () => {
    const course = {
      term: ' Fall 2015',
      school: '   University of Wikipedia ', // includes a non-breaking space
      title: ' Introduction to Editing     '
    };
    const slug = courseUtils.generateTempId(course);
    expect(slug).to.eq('University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)');
  });

  it('collapses multiple whiltespaces into one space', () => {
    const course = {
      term: 'Fall    2015',
      school: ' University    of   Wikipedia            ',
      title: '          Introduction     to         Editing          '
    };
    const slug = courseUtils.generateTempId(course);
    expect(slug).to.eq('University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)');
  });

  it('creates a slug from title and school when term is empty', () => {
    const course = {
      school: ' University of Wikipedia',
      title: 'Introduction to Editing'
    };
    const slug = courseUtils.generateTempId(course);
    expect(slug).to.eq('University_of_Wikipedia/Introduction_to_Editing');
  });
});

describe('CourseUtils.courseSlugRegex', () => {
  it('returns a regex that validates course slug', () => {
    const courseSlugRegex = courseUtils.courseSlugRegex();
    expect(courseSlugRegex.test(' 維基醫學專案 ')).to.eq(true);
    expect(courseSlugRegex.test(' North-Cap University')).to.eq(true);
    expect(courseSlugRegex.test(' مركز حملة')).to.eq(true);
    expect(courseSlugRegex.test('UW, Bothell')).to.eq(true);
    expect(courseSlugRegex.test('वसंत 2017')).to.eq(true);
    expect(courseSlugRegex.test('  ')).to.eq(false);
    expect(courseSlugRegex.test('')).to.eq(false);
  });
});

describe('courseUtils.cleanupCourseSlugComponents', () =>
  it('trims whitespace and collapses multispaces from the slug-related fields of a course object', () => {
    const course = {
      term: ' Fall      2015',
      school: '   University          of       Wikipedia ',
      title: '   Introduction      to      Editing     '
    };
    courseUtils.cleanupCourseSlugComponents(course);
    expect(course.term).to.eq('Fall 2015');
    expect(course.school).to.eq('University of Wikipedia');
    expect(course.title).to.eq('Introduction to Editing');
  })
);

describe('courseUtils.i18n', () => {
  it('outputs an interface message based on a message key and prefix', () => {
    const message = courseUtils.i18n('students', 'courses_generic');
    expect(message).to.eq('Editors');
  });

  it('defaults to the "courses" prefix if prefix is null', () => {
    const message = courseUtils.i18n('students', null);
    expect(message).to.eq('Students');
  });

  it('takes an optional fallback prefix for if prefix is null', () => {
    const message = courseUtils.i18n('class', null, 'revisions');
    expect(message).to.eq('Class');
  });
});

describe('courseUtils.articleFromTitleInput', () => {
  it('replaces underscores', () => {
    const input = 'Robot_selfie';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).to.eq('Robot selfie');
  });

  it('converts Wikipedia urls into titles', () => {
    const input = 'https://en.wikipedia.org/wiki/Robot_selfie';
    const output = courseUtils.articleFromTitleInput(input);

    expect(output.title).to.eq('Robot selfie');
    expect(output.project).to.eq('wikipedia');
    expect(output.language).to.eq('en');
    expect(output.article_url).to.eq(input);
  });

  it('handles mobile urls correctly', () => {
    const input = 'https://en.m.wikipedia.org/wiki/Robot_selfie';
    const output = courseUtils.articleFromTitleInput(input);

    expect(output.title).to.eq('Robot selfie');
    expect(output.project).to.eq('wikipedia');
    expect(output.language).to.eq('en');
    expect(output.article_url).to.eq(input);
  });

  it("correctly parses multilingual wikisource url's", () => {
    const input = 'https://wikisource.org/wiki/Heyder_Cansa';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).to.eq('Heyder Cansa');
    expect(output.project).to.eq('wikisource');
    expect(output.language).to.eq('www');
    expect(output.article_url).to.eq(input);
  });

  it("correctly parses the wikimedia incubator url", () => {
    const input = 'https://incubator.wikimedia.org/wiki/Wp/kiu/Heyder_Cansa';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).to.eq('Wp/kiu/Heyder Cansa');
    expect(output.project).to.eq('wikimedia');
    expect(output.language).to.eq('incubator');
    expect(output.article_url).to.eq(input);
  });

  it('handles url-encoded characters in Wikipedia urls', () => {
    const input = 'https://es.wikipedia.org/wiki/Jalape%C3%B1o';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).to.eq('Jalapeño');
    expect(output.project).to.eq('wikipedia');
    expect(output.language).to.eq('es');
    expect(output.article_url).to.eq(input);
  });
});

describe('courseUtils.articleFromAssignment', () => {
  it('returns an article object with the language, project, title, and url', () => {
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
    expect(article.url).to.eq('https://es.wikipedia.org/wiki/Autofoto');
    expect(article.title).to.eq('Autofoto');
    expect(article.language).to.eq('es');
    expect(article.formatted_title).to.eq('Autofoto');
  });

  it('returns an article object with the language, project, title, and url, comparing it to the default wiki', () => {
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
    expect(article.url).to.eq('https://es.wikipedia.org/wiki/Silvia_Federici');
    expect(article.title).to.eq('Silvia Federici');
    expect(article.language).to.eq('es');
    expect(article.formatted_title).to.eq('es:Silvia Federici');
  });

  it('returns an article object with the language of the default wiki if no langaue is set', () => {
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
    expect(article.url).to.eq('https://es.wikipedia.org/wiki/Silvia_Federici');
    expect(article.title).to.eq('Silvia Federici');
    expect(article.language).to.eq('es');
    expect(article.formatted_title).to.eq('Silvia Federici');
  });

  it('sets wikipedia as the default project', () => {
    const assignment = {
      article_url: 'https://en.wikipedia.org/wiki/Selfie',
      article_title: 'Selfie'
    };
    const defaultWiki = {
      language: 'en'
    };
    const article = courseUtils.articleFromAssignment(assignment, defaultWiki);
    expect(article.project).to.eq('wikipedia');
  });

  it('constructs a url if one is not included', () => {
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
    expect(article.url).to.eq('https://es.wikipedia.org/wiki/Palo_para_autofoto');
  });
});

describe('courseUtils.hasTrainings', () => {
  it('returns false for a weeks array with no trainings', () => {
    const weeks = [{ blocks: [{ training_module_ids: [] }, { training_module_ids: [] }] }];
    const output = courseUtils.hasTrainings(weeks);
    expect(output).to.be.false;
  });

  it('returns true for a weeks array with trainings', () => {
    const weeks = [{ blocks: [{ training_module_ids: [] }, { training_module_ids: [1] }] }];
    const output = courseUtils.hasTrainings(weeks);
    expect(output).to.be.true;
  });
});

describe('courseUtils.formattedArticleTitle', () => {
  it('returns a formatted_article from the same project and language in article and defaultWiki', () => {
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
    expect(article.formatted_title).to.eq('Riot Grrrl');
  });

  it('returns a formatted_article from same project different language', () => {
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
    expect(article.formatted_title).to.eq('fr:Virgine Despentes');
  });

  it('returns a formatted_article from diferent project same language', () => {
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
    expect(article.formatted_title).to.eq('wikiquote:Virginia Woolf');
  });

  it('returns a formatted_article from diferent project different language', () => {
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
    expect(article.formatted_title).to.eq('es:wikiquote:Clara Campoamor');
  });

  it('returns a formatted_article from diferent project and no language', () => {
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
    expect(article.formatted_title).to.eq('wikidata:Judith Butler');
  });
});
