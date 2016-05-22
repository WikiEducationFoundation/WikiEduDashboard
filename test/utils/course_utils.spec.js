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
      school: '   University of Wikipedia ',
      title: ' Introduction to Editing     '
    };
    const slug = courseUtils.generateTempId(course);
    expect(slug).to.eq('University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)');
  });
});

describe('courseUtils.cleanupCourseSlugComponents', () =>
  it('trims whitespace from the slug-related fields of a course object', () => {
    const course = {
      term: ' Fall 2015',
      school: '   University of Wikipedia ',
      title: ' Introduction to Editing     '
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
  it('trims whitespace and replaces underscores', () => {
    const input = ' Robot_selfie  ';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).to.eq('Robot selfie');
  });

  it('converts Wikipedia urls into titles', () => {
    const input = 'https://en.wikipedia.org/wiki/Robot_selfie';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).to.eq('Robot selfie');
    expect(output.project).to.eq('wikipedia');
    expect(output.language).to.eq('en');
  });

  it('handles url-encoded characters in Wikipedia urls', () => {
    const input = 'https://es.wikipedia.org/wiki/Jalape%C3%B1o';
    const output = courseUtils.articleFromTitleInput(input);
    expect(output.title).to.eq('Jalapeño');
    expect(output.project).to.eq('wikipedia');
    expect(output.language).to.eq('es');
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
    const article = courseUtils.articleFromAssignment(assignment);
    expect(article.url).to.eq('https://es.wikipedia.org/wiki/Autofoto');
    expect(article.title).to.eq('Autofoto');
    expect(article.language).to.eq('es');
    expect(article.project).to.eq('wikipedia');
    expect(article.formatted_title).to.eq('es:Autofoto');
  });

  it('sets wikipedia as the default project', () => {
    const assignment = {
      article_url: 'https://en.wikipedia.org/wiki/Selfie',
      article_title: 'Selfie'
    };
    const article = courseUtils.articleFromAssignment(assignment);
    expect(article.project).to.eq('wikipedia');
    expect(article.formatted_title).to.eq('Selfie');
  });
});
