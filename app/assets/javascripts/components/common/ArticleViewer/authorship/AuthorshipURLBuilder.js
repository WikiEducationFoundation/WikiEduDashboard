import URLBuilder from '@components/common/ArticleViewer/utils/URLBuilder';

const WIKIWHO_DOMAIN = 'https://wikiwho-api.wmcloud.org';

// Builds the URLs the authorship/WhoColor feature needs: the WikiWho coloring
// endpoints and the MediaWiki user-id query. Extends the shell's URLBuilder so it
// inherits wikiURL() (used by the user query); the shell never imports this.
export class AuthorshipURLBuilder extends URLBuilder {
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

export default AuthorshipURLBuilder;
