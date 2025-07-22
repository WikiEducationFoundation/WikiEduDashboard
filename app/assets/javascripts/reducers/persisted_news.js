import { RECEIVE_NEWS_CONTENT_LIST, PERSIST_NEWS_CONTENT } from '../constants';

export default function persistedNews(state = {}, action) {
  switch (action.type) {
    case RECEIVE_NEWS_CONTENT_LIST:
    case PERSIST_NEWS_CONTENT:
      return action.news_content_list;
    default:
      return state;
  }
}
