import { fetchArticleDetails } from '../../app/assets/javascripts/actions/article_actions';
import { RECEIVE_ARTICLE_DETAILS } from '../../app/assets/javascripts/constants';
import API from '../../app/assets/javascripts/utils/api.js';
import { getRevisionRange } from '../../app/assets/javascripts/utils/mediawiki_revisions_utils';

jest.mock('../../app/assets/javascripts/utils/api.js', () => ({
  fetchArticleDetails: jest.fn()
}));
jest.mock('../../app/assets/javascripts/utils/mediawiki_revisions_utils', () => ({
  getRevisionRange: jest.fn()
}));

describe('fetchArticleDetails', () => {
  const details = {
    startDate: '2026-08-25T00:00:00.000Z',
    endDate: '2026-12-12T23:59:59.000Z',
    articleTitle: 'Example_article',
    apiUrl: 'https://en.wikipedia.org/w/api.php',
    editors: []
  };

  const run = async (articles) => {
    const dispatch = jest.fn(action => (typeof action === 'function' ? action(dispatch) : action));
    const getState = () => ({ articles: { articles } });
    await fetchArticleDetails(7, 20)(dispatch, getState);
    return dispatch.mock.calls.map(call => call[0]);
  };

  beforeEach(() => {
    API.fetchArticleDetails.mockResolvedValue({ article_details: details });
  });

  it('delivers the details when there are revisions', async () => {
    const revisionRange = { first_revision: { revid: 1 }, last_revision: { revid: 2 } };
    getRevisionRange.mockResolvedValue(revisionRange);

    const actions = await run([]);

    expect(actions).toContainEqual({ type: RECEIVE_ARTICLE_DETAILS, articleId: 7, details, revisionRange });
  });

  it('delivers the details when there are no revisions and the article is not among the course articles', async () => {
    const revisionRange = { first_revision: undefined, last_revision: undefined };
    getRevisionRange.mockResolvedValue(revisionRange);

    const actions = await run([{ id: 99, title: 'Other', mw_page_id: 5 }]);

    expect(actions).toContainEqual({ type: RECEIVE_ARTICLE_DETAILS, articleId: 7, details, revisionRange });
  });
});
