import _ from 'lodash';
import {
  RECEIVE_NEWS_CONTENT_LIST,
  UPDATE_NEWS_CONTENT,
  CANCEL_NEWS_UPDATE,
  DELETE_NEWS_CONTENT,
  CREATE_NEWS_CONTENT,
  RESET_CREATE_NEWS_CONTENT,
  ADD_NEWS_TO_LIST,
} from '../constants';

const initialState = {
  news_content_list: [],
  create_news: {
    content: ''
  }
};

export default function news(state = initialState, action) {
  switch (action.type) {
    case RECEIVE_NEWS_CONTENT_LIST:
      return { ...state, news_content_list: action.news_content_list };
    case CREATE_NEWS_CONTENT:
      return { ...state, create_news: { ...state.create_news, content: action.content } };
    case UPDATE_NEWS_CONTENT:
      return {
        ...state,
        news_content_list: _.map(state.news_content_list, newsItem =>
          (newsItem.id === action.news.id
            ? { ...newsItem, content: action.news.content }
            : newsItem)
        )
      };
    case ADD_NEWS_TO_LIST:
      return { ...state, news_content_list: [...state.news_content_list, action.newNews] };
    case CANCEL_NEWS_UPDATE:
      return { ...initialState, news_content_list: action.news_content };
    case DELETE_NEWS_CONTENT:
      return {
        ...state,
        news_content_list: _.reject(state.news_content_list, { id: action.news_id })
      };
    case RESET_CREATE_NEWS_CONTENT:
      return {
        ...state,
        create_news: {
          content: ''
        }
      };
    default:
      return state;
  }
}
