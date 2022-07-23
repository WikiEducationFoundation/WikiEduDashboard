export default class ArticleUtils {
  // Returns article or item, based on home Wiki project.
  static articlesOrItems(project) {
    return project === 'wikidata' ? 'items' : 'articles';
  }

  // Returns article or item message, based on articles or items keyword.
  static articlesOrItemsMsg(messageKey, articlesOrItems, defaultarticlesOrItems = 'articles') {
    return I18n.t(`${articlesOrItems}.${messageKey}`, {
      defaults: [{ scope: `${defaultarticlesOrItems}.${messageKey}` }]
    });
  }

  // Returns article or item message, based on home Wiki project.
  static I18n(messageKey, project) {
    const articlesOrItems = ArticleUtils.articlesOrItems(project);
    return ArticleUtils.articlesOrItemsMsg(messageKey, articlesOrItems);
  }

  static projectSuffix(project, messageKey) {
    return project === 'wikidata' ? `${messageKey}_wikidata` : messageKey;
  }

  // The following mapping is also present in article.rb file and,
  // wiki.rb has mapping of wikis to namespaces. Hence, any modifications
  // in namespaces should also reflect in the corresponding files.
  static NamespaceIdMapping = {
    0: 'main',
    1: 'talk',
    2: 'user',
    4: 'project',
    6: 'file',
    8: 'mediaWiki',
    10: 'template',
    12: 'help',
    14: 'category',
    104: 'page',
    108: 'book',
    110: 'wikijunior',
    114: 'translation',
    118: 'draft',
    120: 'property',
    122: 'query',
    146: 'lexeme',
    100: {
      wiktionary: 'appendix',
      wikisource: 'portal',
      wikiversity: 'school'
    },
    102: {
      wikisource: 'author',
      wikibooks: 'cookbook',
      wikiversity: 'portal'
    },
    106: {
      wiktionary: 'rhymes',
      wikisource: 'index',
      wikiversity: 'collection'
    }
  };

  // Get tabs and stats title for tabbed course overview stats.
  // Here, wiki_ns_key is key of a course_stats object, which 
  // identifies wiki or wiki-namespace of stats,
  // eg.: 'en.wikibooks.org-namespace-102', 'www.wikidata.org'
  static overviewStatsTitle(wiki_ns_key) {
    // If stats is for wikidata overview, directly return the wiki domain
    if (!wiki_ns_key.includes('namespace')) return wiki_ns_key;
    const project = wiki_ns_key.split('.')[1];
    const wiki_domain = wiki_ns_key.split('-')[0];
    const ns_id = wiki_ns_key.split('-')[2];
    let ns_title = ArticleUtils.NamespaceIdMapping[ns_id];
    if (typeof (ns_title) !== 'string') ns_title = ns_title[project];
    return `${wiki_domain} - ${I18n.t(`namespace.${ns_title}`)}`;
  };
}
