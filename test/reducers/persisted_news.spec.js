import persistedNews from '../../app/assets/javascripts/reducers/persisted_news';
import { RECEIVE_NEWS_CONTENT_LIST, PERSIST_NEWS_CONTENT } from '../../app/assets/javascripts/constants';


describe('persistedNews reducer', () => {
  it('should return the initial state', () => {
    expect(persistedNews(undefined, {})).toEqual({});
  });

  it('should handle RECEIVE_NEWS_CONTENT_LIST', () => {
    const initialState = {};
    const newsContentList = { id: 1, title: 'News Title' };

    const action = {
      type: RECEIVE_NEWS_CONTENT_LIST,
      news_content_list: newsContentList
    };

    expect(persistedNews(initialState, action)).toEqual(newsContentList);
  });

  it('should handle PERSIST_NEWS_CONTENT', () => {
    const initialState = {};
    const newsContentList = { id: 1, title: 'News Title' };

    const action = {
      type: PERSIST_NEWS_CONTENT,
      news_content_list: newsContentList
    };

    expect(persistedNews(initialState, action)).toEqual(newsContentList);
  });

  it('should handle unknown action type', () => {
    const initialState = { id: 1, title: 'News Title' };
    const action = {
      type: 'UNKNOWN_ACTION'
    };

    expect(persistedNews(initialState, action)).toEqual(initialState);
  });
});
