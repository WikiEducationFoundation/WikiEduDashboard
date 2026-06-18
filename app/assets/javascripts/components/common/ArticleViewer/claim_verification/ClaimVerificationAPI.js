import request from '~/app/assets/javascripts/utils/request';

// The claim-verification side of the article viewer. Unlike authorship (which
// hits cross-site Wikimedia APIs), these hit our own course-scoped Rails
// endpoints: the exercise state (taken claim + pickable articles), an article's
// parsed HTML with cited claims tagged, and taking a claim on. The shell never
// imports this; only the claim feature does.
export class ClaimVerificationAPI {
  constructor({ courseSlug }) {
    this.courseSlug = courseSlug;
  }

  // Course slugs contain slashes (School/Title_(Term)); the route glob matches
  // them, so the slug goes into the path unescaped, matching the rest of the
  // course SPA's URLs.
  basePath() {
    return `/courses/${this.courseSlug}/verify_claim`;
  }

  fetchState() {
    return request(`${this.basePath()}/state`)
      .then(response => this.__json(response, 'Exercise state request failed'));
  }

  fetchAnnotatedArticle(articleId) {
    return request(`${this.basePath()}/annotated_article?article_id=${articleId}`)
      .then(response => this.__json(response, 'Annotated article request failed'));
  }

  take({ articleId, sentence, refId }) {
    const body = JSON.stringify({ article_id: articleId, sentence, ref_id: refId });
    return request(`${this.basePath()}/take`, { method: 'POST', body })
      .then(response => this.__json(response, 'Take claim request failed'));
  }

  __json(response, message) {
    if (!response.ok) throw new Error(`${message} [${response.status}]`);
    return response.json();
  }
}

export default ClaimVerificationAPI;
