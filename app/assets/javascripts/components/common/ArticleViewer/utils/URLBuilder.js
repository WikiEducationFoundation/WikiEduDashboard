// Builds the MediaWiki URLs the article-viewer shell needs: the wiki origin and
// the `action=parse` endpoint for the article's rendered HTML. Authorship/WhoColor
// URLs live in the authorship feature's AuthorshipURLBuilder, which extends this.
export class URLBuilder {
  constructor({ article, users }) {
    this.article = article;
    this.users = users;
  }

  parsedArticleURL(lastRevisionId) {
    const { title } = this.article;
    if (!title) throw new TypeError('Article title is missing!');

    const base = this.wikiURL();
    let url;
    if (lastRevisionId) {
      const query = `${base}/w/api.php?action=parse&oldid=${lastRevisionId}&disableeditsection=true&redirects=true&format=json`;
      url = `${query}`;
    } else {
      const query = `${base}/w/api.php?action=parse&disableeditsection=true&redirects=true&format=json`;
      url = `${query}&page=${encodeURIComponent(title)}`;
    }
    return url;
  }

  wikiURL() {
    const language = this.article.language || 'www';
    const project = this.article.project;

    if (!project) throw new TypeError('Article project is missing!');

    const url = `https://${language}.${project}.org`;
    return encodeURI(url);
  }
}

export default URLBuilder;
