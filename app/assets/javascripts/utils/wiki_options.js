import '../../../../test/testHelper'

const languages = JSON.parse(WikiLanguages);
const projects = JSON.parse(WikiProjects).filter(proj => proj !== 'wikidata');
const WIKI_OPTIONS = languages.map(language =>
  projects.map((project) => {
    const value = { language, project };
    const label = `${language}.${project}.org`;
    return { value, label };
  })
).reduce((a, b) => a.concat(b));
// Wikidata is multilingual with English as the default language and therefore has
// a custom label so it is more intuitive.
WIKI_OPTIONS.unshift({ value: { language: 'en', project: 'wikidata' }, label: 'www.wikidata.org' });
// Wikisource has a standalone www.wikisource.org in addition to language based sites like es.wikisource.org
WIKI_OPTIONS.unshift({ value: { language: 'en', project: 'wikisource' }, label: 'www.wikisource.org' });
// We are inserting the above at first so users are aware of this option and it doesn't disappear
// among the limited results

export default WIKI_OPTIONS;
