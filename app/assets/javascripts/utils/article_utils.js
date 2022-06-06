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

  // Mapping of namespace to its id
  static namespaceToId(namespace) {
    const mapping = {
      article: 0,
      talk: 1,
      user: 2
    };
    return mapping[namespace];
  }
}
