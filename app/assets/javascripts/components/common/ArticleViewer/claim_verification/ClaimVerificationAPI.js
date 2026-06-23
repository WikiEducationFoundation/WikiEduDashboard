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

  // The article is rendered at the flagged revision; its pre-harvested claims are
  // tagged in the returned HTML.
  fetchAnnotatedArticle(articleId, mwRevId) {
    return request(`${this.basePath()}/annotated_article?article_id=${articleId}&mw_rev_id=${mwRevId}`)
      .then(response => this.__json(response, 'Annotated article request failed'));
  }

  // The claim is already in the pool; we assign the chosen one by id.
  take({ articleId, verificationClaimId }) {
    const body = JSON.stringify({ article_id: articleId, verification_claim_id: verificationClaimId });
    return request(`${this.basePath()}/take`, { method: 'POST', body })
      .then(response => this.__json(response, 'Take claim request failed'));
  }

  __json(response, message) {
    if (!response.ok) throw new Error(`${message} [${response.status}]`);
    return response.json();
  }
}

export default ClaimVerificationAPI;
