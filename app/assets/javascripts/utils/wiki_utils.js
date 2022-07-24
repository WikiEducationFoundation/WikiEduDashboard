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

// Get label for tabs and stats data of tabbed course overview stats.
// Here, wiki_ns_key is key of a course_stats object, which
// identifies wiki or wiki-namespace of stats,
// eg.: 'en.wikibooks.org-namespace-102', 'www.wikidata.org'
const overviewStatsLabel = (wiki_ns_key) => {
  // If stats are for wikidata overview, directly return the wiki domain
  if (!wiki_ns_key.includes('namespace')) return wiki_ns_key;
  const project = wiki_ns_key.split('.')[1];
  const wiki_domain = wiki_ns_key.split('-')[0];
  const ns_id = wiki_ns_key.split('-')[2];
  let ns_title = ArticleUtils.NamespaceIdMapping[ns_id];
  if (typeof (ns_title) !== 'string') ns_title = ns_title[project];
  return `${wiki_domain} - ${I18n.t(`namespace.${ns_title}`)}`;
};
export { trackedWikisMaker, formatOption, toWikiDomain, overviewStatsLabel };
