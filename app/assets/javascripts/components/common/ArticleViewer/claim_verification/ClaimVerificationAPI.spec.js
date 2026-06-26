import { ClaimVerificationAPI } from './ClaimVerificationAPI';

const okResponse = payload => () => Promise.resolve({
  ok: true, status: 200, json: () => Promise.resolve(payload)
});

describe('ClaimVerificationAPI', () => {
  const api = new ClaimVerificationAPI({ courseSlug: 'School/Claims_2024' });

  describe('.basePath()', () => {
    it('builds the course-scoped base path with the slug unescaped', () => {
      expect(api.basePath()).toEqual('/courses/School/Claims_2024/verify_claim');
    });
  });

  describe('.fetchState()', () => {
    it('GETs the state endpoint and resolves its JSON', async () => {
      const payload = { assignment: null, articles: [{ id: 1, title: 'Otter' }] };
      global.fetch = jest.fn(okResponse(payload));
      const result = await api.fetchState();
      expect(global.fetch.mock.calls[0][0]).toContain('/courses/School/Claims_2024/verify_claim/state');
      expect(result).toEqual(payload);
    });
  });

  describe('.fetchAnnotatedArticle()', () => {
    it('requests the annotated-article URL with the article id and revision', async () => {
      const payload = { html: '<p>annotated</p>', mw_rev_id: 555 };
      global.fetch = jest.fn(okResponse(payload));
      const result = await api.fetchAnnotatedArticle(118, 555);
      expect(global.fetch.mock.calls[0][0])
        .toContain('/verify_claim/annotated_article?article_id=118&mw_rev_id=555');
      expect(result).toEqual(payload);
    });

    it('rejects when the response is not ok', async () => {
      global.fetch = jest.fn(() => Promise.resolve({ ok: false, status: 500, json: () => Promise.resolve({}) }));
      await expect(api.fetchAnnotatedArticle(118, 555)).rejects.toThrow('[500]');
    });
  });

  describe('.take()', () => {
    it('POSTs the chosen claim id and resolves the assignment', async () => {
      const payload = { assignment: { claim: { sentence: 'Otters use tools.' } } };
      global.fetch = jest.fn(okResponse(payload));
      const result = await api.take({ articleId: 5, verificationClaimId: 42 });
      const [url, options] = global.fetch.mock.calls[0];
      expect(url).toContain('/courses/School/Claims_2024/verify_claim/take');
      expect(options.method).toEqual('POST');
      expect(JSON.parse(options.body)).toEqual({ article_id: 5, verification_claim_id: 42 });
      expect(result).toEqual(payload);
    });

    it('rejects with the HTTP status attached when the take is forbidden', async () => {
      global.fetch = jest.fn(() => Promise.resolve({ ok: false, status: 403, json: () => Promise.resolve({}) }));
      await expect(api.take({ articleId: 5, verificationClaimId: 42 }))
        .rejects.toMatchObject({ status: 403 });
    });
  });
});
