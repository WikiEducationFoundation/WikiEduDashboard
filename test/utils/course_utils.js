import '../testHelper';
import '../../public/assets/javascripts/i18n/en';
import CourseUtils from '../../app/assets/javascripts/utils/course_utils';

describe('CourseUtils.generateTempId', () => {
  it('creates a slug from term, title and school', () => {
    const course = {
      term: 'Fall 2015',
      school: 'University of Wikipedia',
      title: 'Introduction to Editing'
    };
    const slug = CourseUtils.generateTempId(course);
    expect(slug).to.eq('University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)');
  });

  it('trims unnecessary whitespace', () => {
    const course = {
      term: ' Fall 2015',
      school: '   University of Wikipedia ',
      title: ' Introduction to Editing     '
    };
    const slug = CourseUtils.generateTempId(course);
    expect(slug).to.eq('University_of_Wikipedia/Introduction_to_Editing_(Fall_2015)');
  });
});

describe('CourseUtils.cleanupCourseSlugComponents', () =>
  it('trims whitespace from the slug-related fields of a course object', () => {
    const course = {
      term: ' Fall 2015',
      school: '   University of Wikipedia ',
      title: ' Introduction to Editing     '
    };
    CourseUtils.cleanupCourseSlugComponents(course);
    expect(course.term).to.eq('Fall 2015');
    expect(course.school).to.eq('University of Wikipedia');
    expect(course.title).to.eq('Introduction to Editing');
  })
);

describe('CourseUtils.i18n', () => {
  it('outputs an interface message based on a message key and prefix', () => {
    const message = CourseUtils.i18n('students', 'courses_generic');
    expect(message).to.eq('Editors');
  });

  it('defaults to the "courses" prefix if prefix is null', () => {
    const message = CourseUtils.i18n('students', null);
    expect(message).to.eq('Students');
  });

  it('takes an optional fallback prefix for if prefix is null', () => {
    const message = CourseUtils.i18n('class', null, 'revisions');
    expect(message).to.eq('Class');
  });
});
