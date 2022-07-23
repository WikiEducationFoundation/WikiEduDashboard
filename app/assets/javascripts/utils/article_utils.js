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
}
