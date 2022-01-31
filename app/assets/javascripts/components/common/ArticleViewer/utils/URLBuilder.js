const WIKIWHO_DOMAIN = 'https://wikiwho-api.wmcloud.org';

export class URLBuilder {
  constructor({ article, users }) {
    this.article = article;
    this.users = users;
  }

  parsedArticleURL() {
    const { title } = this.article;
    if (!title) throw new TypeError('Article title is missing!');

    const base = this.wikiURL();
    const query = `${base}/w/api.php?action=parse&disableeditsection=true&format=json`;
    const url = `${query}&page=${encodeURIComponent(title)}`;

    return url;
  }

  wikiURL() {
    const language = this.article.language || 'www';
    const project = this.article.project;

    if (!project) throw new TypeError('Article project is missing!');

    const url = `https://${language}.${project}.org`;
    return encodeURI(url);
  }

  wikiwhoColorURL() {
    const { language, title } = this.article;

    if (!language) throw new TypeError('Article language is missing!');
    if (!title) throw new TypeError('Article title is missing!');

    const url = `${WIKIWHO_DOMAIN}/${language}/whocolor/v1.0.0-beta/${title}/`;
    return encodeURI(url);
  }

  wikiwhoColorRevisionURL() {
    const { language, title } = this.article;

    if (!language) throw new TypeError('Article language is missing!');
    if (!title) throw new TypeError('Article title is missing!');

    const query = '?o_rev_id=true&editor=true&token_id=true&out=true&in=true';
    const url = `${WIKIWHO_DOMAIN}/${language}/api/v1.0.0-beta/rev_content/${title}/${query}`;
    return encodeURI(url);
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
