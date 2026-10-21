import { profileCsv } from '../../app/assets/javascripts/utils/user_profile_export';

describe('profile CSV export', () => {
  it('preserves nested course and article data, Unicode, quotes and line breaks', () => {
    const csv = profileCsv({
      username: 'José',
      articles_by_course: [
        {
          course_title: 'Curso',
          articles: [{ title: 'Una "página",\nsegunda línea', word_count: 42 }]
        }
      ]
    });
    expect(csv).toContain('"username","José"');
    expect(csv).toContain('"articles_by_course.0.course_title","Curso"');
    expect(csv).toContain('"articles_by_course.0.articles.0.title","Una ""página"",\nsegunda línea"');
    expect(csv).toContain('"articles_by_course.0.articles.0.word_count","42"');
  });

  it('neutralizes spreadsheet formulas while preserving numbers and null values', () => {
    const csv = profileCsv({ title: '=HYPERLINK("bad")', count: -3, language: null });
    expect(csv).toContain('"title","\'=HYPERLINK(""bad"")"');
    expect(csv).toContain('"count","-3"');
    expect(csv).toContain('"language",""');
  });
});
