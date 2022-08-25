import ArticleUtils from './article_utils';

const toWikiDomain = (wiki) => {
  const subdomain = wiki.language || 'www';
  return `${subdomain}.${wiki.project}.org`;
};

const formatOption = (wiki) => {
  return {
    value: JSON.stringify(wiki),
    label: toWikiDomain(wiki)
  };
};

const trackedWikisMaker = (course) => {
  let trackedWikis = [];
  if (course.wikis) {
    trackedWikis = course.wikis.map((wiki) => {
      wiki.language = wiki.language || 'www'; // for multilingual wikis language is null
      return formatOption(wiki);
    });
  }
  return trackedWikis;
};

// Gives label for wiki-namespace stats
// eg.: 'en.wikibooks.org-namespace-102' => 'en.wikibooks.org - Cookbook'
const wikiNamespaceLabel = (wiki_domain, namespace) => {
  if (namespace === undefined) return wiki_domain;
  const project = wiki_domain.split('.')[1];
  let ns_label = ArticleUtils.NamespaceIdMapping[namespace];
  if (typeof (ns_label) !== 'string') ns_label = ns_label[project];
  return `${wiki_domain} - ${I18n.t(`namespace.${ns_label}`)}`;
};
export { trackedWikisMaker, formatOption, toWikiDomain, wikiNamespaceLabel };
