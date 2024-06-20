import ArticleUtils from './article_utils';

const toWikiDomain = (wiki) => {
  const language = (wiki.language) ? `${wiki.language}.` : 'www.';
  const subdomain = (wiki.project === 'wikisource' && !wiki.language) ? '' : language;
  return `${subdomain}${wiki.project}.org`;
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

const getArticleUrl = (wiki, title) => {
  const language = wiki.language || 'www';
  const project = wiki.project;
  const domain = `${language}.${project}.org`;
  return `https://${domain}/wiki/${title}`;
};

const getLastWikiEdit = async (articleUrl, username) => {
  // username is used to replace Special:MyPage in wiki with username
  try {
      const parsedUrl = new URL(articleUrl);
      const articleTitle = decodeURIComponent(parsedUrl.pathname.split('/wiki/')[1].replace(/\+/g, ' ')).replace(/_/g, ' ').replace('Special:MyPage', `User:${username}`);
      const wikiApiUrl = `https://${parsedUrl.hostname}/w/api.php`;
      const response = await fetch(`${wikiApiUrl}?action=query&prop=revisions&titles=${encodeURIComponent(articleTitle)}&format=json&rvprop=timestamp|user&rvlimit=1&origin=*`);
      const data = await response.json();

      const pages = data.query.pages;
      const pageId = Object.keys(pages)[0];
      if (pageId === -1) {
        // page not found
        return null;
      }
      const lastEdit = pages[pageId].revisions[0];

      return {
          user: lastEdit.user,
          timestamp: lastEdit.timestamp
      };
  } catch (error) {
      return null;
  }
};

export { trackedWikisMaker, formatOption, toWikiDomain, wikiNamespaceLabel, getArticleUrl, getLastWikiEdit };
