import configureMockStore from 'redux-mock-store';
import thunk from 'redux-thunk';
import * as actions from '../../app/assets/javascripts/actions/news_action';
import * as types from '../../app/assets/javascripts/constants';
import API from '../../app/assets/javascripts/utils/api';
import logErrorMessage from '../../app/assets/javascripts/utils/log_error_message';

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

jest.mock('../../app/assets/javascripts/utils/api', () => ({
  __esModule: true,
  default: {
    fetchNews: jest.fn(),
    createNews: jest.fn(),
    updateNews: jest.fn(),
    deleteNews: jest.fn()
  }
}));

jest.mock('../../app/assets/javascripts/utils/log_error_message');

describe('News Content Actions', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should fetch all news content successfully', async () => {
    const newsContentList = [{ id: 1, content: 'News 1' }, { id: 2, content: 'News 2' }];
    const expectedActions = [{ type: types.RECEIVE_NEWS_CONTENT_LIST, news_content_list: newsContentList }];

    API.fetchNews.mockResolvedValueOnce(newsContentList);

    const store = mockStore({ news: {} });

    await store.dispatch(actions.fetchAllNewsContent());
    expect(store.getActions()).toEqual(expectedActions);
  });

  it('should create news content locally', () => {
    const newsContent = { id: 1, content: 'New News' };
    const expectedAction = { type: types.CREATE_NEWS_CONTENT, content: newsContent };

    const store = mockStore({ news: {} });

    store.dispatch(actions.createNewsContent(newsContent));
    expect(store.getActions()).toEqual([expectedAction]);
  });

  it('should cache news content edit', () => {
    const editedNews = { id: 1, content: 'Edited News' };
    const expectedAction = { type: types.UPDATE_NEWS_CONTENT, news: editedNews };

    const store = mockStore({});

    store.dispatch(actions.cacheNewsContentEdit(editedNews));
    expect(store.getActions()).toEqual([expectedAction]);
  });

  it('should cancel news content editing', () => {
    const persistedNews = [{ id: 1, content: 'News 1' }, { id: 2, content: 'News 2' }];
    const expectedAction = { type: types.CANCEL_NEWS_UPDATE, news_content: persistedNews };

    const getState = () => ({ persistedNews });

    const store = mockStore(getState());

    store.dispatch(actions.cancelNewsContentEditing());
    expect(store.getActions()).toEqual([expectedAction]);
  });

  it('should save edited news content to the server', async () => {
    const newsId = 1;
    const editedContent = 'Edited Content';
    const expectedUpdatedNewsContentList = [
      { id: 1, content: editedContent },
      { id: 2, content: 'News 2' }
    ];

    const getState = () => ({ news: { news_content_list: expectedUpdatedNewsContentList } });

    API.updateNews.mockResolvedValueOnce({ id: newsId });

    const store = mockStore(getState());

    await store.dispatch(actions.saveEditedNewsContent(newsId));

    const action = store.getActions();

    const persistedNewsContentAction = action.find(x => x.type === types.PERSIST_NEWS_CONTENT);

    expect(persistedNewsContentAction).toBeTruthy();
    expect(persistedNewsContentAction.news_content_list).toEqual(expectedUpdatedNewsContentList);
  });


  it('should delete selected news content', async () => {
    const newsId = 1;
    const expectedActions = [{ type: types.DELETE_NEWS_CONTENT, news_id: newsId }];

    const getState = () => ({ news: { news_content_list: [{ id: newsId }] } });

    API.deleteNews.mockResolvedValueOnce({ id: newsId });

    const store = mockStore({}, getState);

    await store.dispatch(actions.deleteSelectedNewsContent(newsId));
    expect(store.getActions()).toEqual(expectedActions);
  });

  it('should reset create news state', () => {
    const expectedAction = { type: types.RESET_CREATE_NEWS_CONTENT };

    const store = mockStore({});

    store.dispatch(actions.resetCreateNewsState());
    expect(store.getActions()).toEqual([expectedAction]);
  });

  it('should log error message when fetching news content fails', async () => {
    const error = new Error('Failed to fetch news content');
    API.fetchNews.mockRejectedValueOnce(error);

    const store = mockStore({});

    await store.dispatch(actions.fetchAllNewsContent());
    expect(logErrorMessage).toHaveBeenCalledWith('Error fetching news content:', error);
  });
});
