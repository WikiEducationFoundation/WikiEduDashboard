
export default class ArticlesOrItemsUtils {
// Returns article or item, based on home Wiki.
  static articlesOrItems(project) {
    return project === 'wikidata' ? 'items' : 'articles';
  }

// Returns article or item message.
  static articlesOrItemsI18n(messageKey, articlesOrItems, defaultarticlesOrItems = 'articles') {
    return I18n.t(`${articlesOrItems}.${messageKey}`, {
      defaults: [{ scope: `${defaultarticlesOrItems}.${messageKey}` }]
    });
  }
}
