import deepFreeze from 'deep-freeze';
import studentArticles from '../../app/assets/javascripts/reducers/student_articles';
import {
  RECEIVE_STUDENT_ARTICLES,
  RECEIVE_MORE_STUDENT_ARTICLES
} from '../../app/assets/javascripts/constants/student_articles';
import '../testHelper';

const article = id => ({ id, articles_course_id: id, title: `article_${id}` });
const page = (ids, userId = 5, pageSize = 2, type = RECEIVE_STUDENT_ARTICLES) => ({
  type,
  userId,
  pageSize,
  data: { course: { articles: ids.map(article) } }
});

describe('studentArticles reducer', () => {
  test('stores a first page under the student id', () => {
    const state = studentArticles(undefined, page([1, 2]));
    expect(state[5].articles.map(a => a.id)).toEqual([1, 2]);
    expect(state[5].limitReached).toBe(false);
  });

  test('marks the list as complete when a page comes back short', () => {
    const state = studentArticles(undefined, page([1]));
    expect(state[5].limitReached).toBe(true);
  });

  test('appends more articles without duplicates', () => {
    const first = deepFreeze(studentArticles(undefined, page([1, 2])));
    const next = studentArticles(first, page([2, 3], 5, 2, RECEIVE_MORE_STUDENT_ARTICLES));
    expect(next[5].articles.map(a => a.id)).toEqual([1, 2, 3]);
    expect(next[5].limitReached).toBe(false);
  });

  test('keeps each student separate', () => {
    const first = deepFreeze(studentArticles(undefined, page([1, 2], 5)));
    const next = studentArticles(first, page([9], 6));
    expect(next[5].articles.map(a => a.id)).toEqual([1, 2]);
    expect(next[6].articles.map(a => a.id)).toEqual([9]);
  });
});
