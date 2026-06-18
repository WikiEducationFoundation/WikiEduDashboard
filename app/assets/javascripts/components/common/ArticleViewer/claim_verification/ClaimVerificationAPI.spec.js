import { ClaimVerificationAPI } from './ClaimVerificationAPI';

describe('ClaimVerificationAPI', () => {
  const api = new ClaimVerificationAPI({ courseSlug: 'School/Claims_2024' });

  describe('.annotatedArticleURL()', () => {
    it('builds the course-scoped endpoint with the article id, slug unescaped', () => {
      expect(api.annotatedArticleURL(118))
        .toEqual('/courses/School/Claims_2024/verify_claim/annotated_article?article_id=118');
    });
  });

  describe('.fetchAnnotatedArticle()', () => {
    it('requests the annotated-article URL and resolves the parsed JSON', async () => {
      const payload = { html: '<p>annotated</p>', mw_rev_id: 555 };
      global.fetch = jest.fn(() => Promise.resolve({ ok: true, json: () => Promise.resolve(payload) }));

      const result = await api.fetchAnnotatedArticle(118);

      expect(global.fetch).toHaveBeenCalledWith(
        '/courses/School/Claims_2024/verify_claim/annotated_article?article_id=118',
        { headers: { Accept: 'application/json' } }
      );
      expect(result).toEqual(payload);
    });

    it('rejects when the response is not ok', async () => {
      global.fetch = jest.fn(() => Promise.resolve({ ok: false, status: 500 }));
      await expect(api.fetchAnnotatedArticle(118)).rejects.toThrow('[500]');
    });
  });
});
