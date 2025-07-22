const WIKIWHO_DOMAIN = 'https://wikiwho-api.wmcloud.org';

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
      const query = `${base}/w/api.php?action=parse&oldid=${lastRevisionId}&disableeditsection=true&format=json`;
      url = `${query}`;
    } else {
      const query = `${base}/w/api.php?action=parse&disableeditsection=true&format=json`;
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

  wikiwhoColorURL(lastRevisionId) {
    const { language, title } = this.article;

    if (!language) throw new TypeError('Article language is missing!');
    if (!title) throw new TypeError('Article title is missing!');

    // Add `/0` to the end of the URL to work around wikiwho API bug with article titles that include slashes.
    // See https://github.com/wikimedia/wikiwho_api/pull/4/commits/8f421a20c62288a1a29bcef75fffa0a21d2c92a6
    const revisionId = lastRevisionId || 0;
    const url = `${WIKIWHO_DOMAIN}/${language}/whocolor/v1.0.0-beta/${encodeURIComponent(title)}/${revisionId}/`;
    return url;
  }

  wikiwhoColorRevisionURL() {
    const { language, title } = this.article;

    if (!language) throw new TypeError('Article language is missing!');
    if (!title) throw new TypeError('Article title is missing!');

    const query = '?o_rev_id=true&editor=true&token_id=true&out=true&in=true';
    const url = `${WIKIWHO_DOMAIN}/${language}/api/v1.0.0-beta/rev_content/${encodeURIComponent(title)}/${query}`;
    return url;
  }

  wikiUserQueryURL(users = this.users) {
    if (!users || !users.length) throw new TypeError('No users provided!');

    const base = `${this.wikiURL()}/w/api.php`;
    const params = encodeURIComponent(users.join('|'));
    const url = `${base}?action=query&list=users&format=json&ususers=`;
    return encodeURI(url) + params;
  }
}

export default URLBuilder;
