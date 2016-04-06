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

describe('CourseUtils.formatArticleTitle', () => {
  it('trims whitespace and replaces underscores', () => {
    const input = ' Robot_selfie  ';
    const output = CourseUtils.formatArticleTitle(input);
    expect(output).to.eq('Robot selfie');
  });

  it('converts Wikipedia urls into titles', () => {
    const input = 'https://en.wikipedia.org/wiki/Robot_selfie';
    const output = CourseUtils.formatArticleTitle(input);
    expect(output).to.eq('Robot selfie');
  });

  it('handles url-encoded characters in Wikipedia urls', () => {
    const input = 'https://en.wikipedia.org/wiki/Jalape%C3%B1o';
    const output = CourseUtils.formatArticleTitle(input);
    expect(output).to.eq('Jalapeño');
  });
});
