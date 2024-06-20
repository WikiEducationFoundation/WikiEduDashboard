import newsReducer from '../../app/assets/javascripts/reducers/news';
import {
  RECEIVE_NEWS_CONTENT_LIST,
  UPDATE_NEWS_CONTENT,
  CREATE_NEWS_CONTENT,
  ADD_NEWS_TO_LIST,
  CANCEL_NEWS_UPDATE,
  DELETE_NEWS_CONTENT,
  RESET_CREATE_NEWS_CONTENT,
} from '../../app/assets/javascripts/constants';

describe('news reducer', () => {
  it('should return the initial state', () => {
    expect(newsReducer(undefined, {})).toEqual({
      news_content_list: [],
      create_news: {
        content: ''
      }
    });
  });

  it('should handle RECEIVE_NEWS_CONTENT_LIST', () => {
    const newsList = [{ id: 1, content: 'News 1' }, { id: 2, content: 'News 2' }];
    const action = { type: RECEIVE_NEWS_CONTENT_LIST, news_content_list: newsList };
    expect(newsReducer(undefined, action)).toEqual({
      news_content_list: newsList,
      create_news: {
        content: ''
      }
    });
  });

  it('should handle CREATE_NEWS_CONTENT', () => {
    const content = 'New content';
    const action = { type: CREATE_NEWS_CONTENT, content };
    expect(newsReducer(undefined, action)).toEqual({
      news_content_list: [],
      create_news: {
        content: 'New content'
      }
    });
  });

  it('should handle UPDATE_NEWS_CONTENT', () => {
    const initialState = {
      news_content_list: [{ id: 1, content: 'News 1' }, { id: 2, content: 'News 2' }],
      create_news: {
        content: ''
      }
    };
    const updatedNews = { id: 2, content: 'Updated News 2' };
    const action = { type: UPDATE_NEWS_CONTENT, news: updatedNews };
    expect(newsReducer(initialState, action)).toEqual({
      news_content_list: [{ id: 1, content: 'News 1' }, { id: 2, content: 'Updated News 2' }],
      create_news: {
        content: ''
      }
    });
  });

  it('should handle ADD_NEWS_TO_LIST', () => {
    const initialState = {
      news_content_list: [{ id: 1, content: 'News 1' }],
      create_news: {
        content: ''
      }
    };
    const newNews = { id: 2, content: 'New News' };
    const action = { type: ADD_NEWS_TO_LIST, newNews };
    expect(newsReducer(initialState, action)).toEqual({
      news_content_list: [{ id: 1, content: 'News 1' }, { id: 2, content: 'New News' }],
      create_news: {
        content: ''
      }
    });
  });

  it('should handle CANCEL_NEWS_UPDATE', () => {
    const initialState = {
      news_content_list: [{ id: 1, content: 'News 1' }, { id: 2, content: 'News 2' }],
      create_news: {
        content: ''
      }
    };
    const action = { type: CANCEL_NEWS_UPDATE, news_content: [{ id: 1, content: 'News 1' }] };
    expect(newsReducer(initialState, action)).toEqual({
      news_content_list: [{ id: 1, content: 'News 1' }],
      create_news: {
        content: ''
      }
    });
  });

  it('should handle DELETE_NEWS_CONTENT', () => {
    const initialState = {
      news_content_list: [{ id: 1, content: 'News 1' }, { id: 2, content: 'News 2' }],
      create_news: {
        content: ''
      }
    };
    const action = { type: DELETE_NEWS_CONTENT, news_id: 1 };
    expect(newsReducer(initialState, action)).toEqual({
      news_content_list: [{ id: 2, content: 'News 2' }],
      create_news: {
        content: ''
      }
    });
  });

  it('should handle RESET_CREATE_NEWS_CONTENT', () => {
    const initialState = {
      news_content_list: [{ id: 1, content: 'News 1' }],
      create_news: {
        content: 'New content'
      }
    };
    const action = { type: RESET_CREATE_NEWS_CONTENT };
    expect(newsReducer(initialState, action)).toEqual({
      news_content_list: [{ id: 1, content: 'News 1' }],
      create_news: {
        content: ''
      }
    });
  });
});
