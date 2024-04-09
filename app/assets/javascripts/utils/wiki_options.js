const projects = JSON.parse(WikiProjects);
// Remove wikidata and wikimedia as they require special implementation.
projects.splice(projects.indexOf('wikidata'), 1);
projects.splice(projects.indexOf('wikimedia'), 1);

const languages = JSON.parse(WikiLanguages);
// Remove 'meta' language, it requires speciali implementation below.
languages.splice(languages.indexOf('meta'), 1);

const WIKI_OPTIONS = languages.map(language =>
  projects.map((project) => {
    const value = JSON.stringify({ language, project });
    const label = `${language}.${project}.org`;
    return { value, label };
  })
).reduce((a, b) => a.concat(b));

// Wikimedia has only three trackable wikis
WIKI_OPTIONS.unshift({ value: JSON.stringify({ language: 'meta', project: 'wikimedia' }), label: 'meta.wikimedia.org' });

WIKI_OPTIONS.unshift({ value: JSON.stringify({ language: 'commons', project: 'wikimedia' }), label: 'commons.wikimedia.org' });

WIKI_OPTIONS.unshift({ value: JSON.stringify({ language: 'incubator', project: 'wikimedia' }), label: 'incubator.wikimedia.org' });

// Wikidata is multilingual with English as the default language and therefore has
// a custom label so it is more intuitive.
WIKI_OPTIONS.unshift({ value: JSON.stringify({ language: 'www', project: 'wikidata' }), label: 'www.wikidata.org' });

// Wikisource has a standalone www.wikisource.org in addition to language based sites like es.wikisource.org
WIKI_OPTIONS.unshift({ value: JSON.stringify({ language: 'www', project: 'wikisource' }), label: 'www.wikisource.org' });

// We are inserting the above at first so users are aware of this option and it doesn't disappear
// among the limited results

export default WIKI_OPTIONS;
