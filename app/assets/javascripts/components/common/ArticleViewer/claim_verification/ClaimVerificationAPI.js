// The claim-verification side of the article viewer. Unlike authorship (which
// hits cross-site Wikimedia APIs), this fetches our own Rails endpoint, which
// returns the article's parsed HTML with cited claims already tagged (and links
// absolutized) server-side. The shell never imports this; only the claim feature
// does.
export class ClaimVerificationAPI {
  constructor({ courseSlug }) {
    this.courseSlug = courseSlug;
  }

  // Course slugs contain slashes (School/Title_(Term)); the route glob matches
  // them, so the slug goes into the path unescaped, matching the server-rendered
  // links elsewhere in the exercise.
  annotatedArticleURL(articleId) {
    return `/courses/${this.courseSlug}/verify_claim/annotated_article?article_id=${articleId}`;
  }

  fetchAnnotatedArticle(articleId) {
    return fetch(this.annotatedArticleURL(articleId), {
      headers: { Accept: 'application/json' }
    }).then((response) => {
      if (!response.ok) throw new Error(`Annotated article request failed [${response.status}]`);
      return response.json();
    });
  }
}

export default ClaimVerificationAPI;
