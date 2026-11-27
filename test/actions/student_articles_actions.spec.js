import { fetchStudentArticles, fetchMoreStudentArticles } from '../../app/assets/javascripts/actions/articles_actions';
import {
  API_FAIL,
  RECEIVE_STUDENT_ARTICLES,
  RECEIVE_MORE_STUDENT_ARTICLES
} from '../../app/assets/javascripts/constants';
import { fetchWikidataLabelsForArticles } from '../../app/assets/javascripts/actions/wikidata_actions';

jest.mock('../../app/assets/javascripts/utils/log_error_message');
jest.mock('../../app/assets/javascripts/actions/wikidata_actions', () => ({
  fetchWikidataLabelsForArticles: jest.fn()
}));

const rows = ids => ids.map(id => ({ id, articles_course_id: id }));
const getState = (studentArticles = {}) => () => ({ studentArticles });

const mockResponse = (body, ok = true, status = 200) => {
  global.fetch = jest.fn(() => Promise.resolve({
    ok,
    status,
    json: () => Promise.resolve(body)
  }));
};

describe('student articles actions', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.clearAllMocks();
  });

  describe('fetchStudentArticles', () => {
    it('asks for the first page of that student with user_id and no after_id', async () => {
      mockResponse({ course: { articles: [] } });
      await fetchStudentArticles('School/Course_(2026)', 42)(jest.fn(), getState());

      const url = global.fetch.mock.calls[0][0];
      expect(url).toContain('user_id=42');
      expect(url).toContain('limit=500');
      expect(url).not.toContain('after_id');
    });

    it('does not fetch again when the student is already loaded', async () => {
      mockResponse({ course: { articles: [] } });
      await fetchStudentArticles('School/Course_(2026)', 42)(
        jest.fn(), getState({ 42: { articles: [], limitReached: true } })
      );

      expect(global.fetch).not.toHaveBeenCalled();
    });

    it('dispatches RECEIVE_STUDENT_ARTICLES with the page, the student and the page size', async () => {
      const page = rows([3, 4]);
      mockResponse({ course: { articles: page } });
      const dispatch = jest.fn();
      await fetchStudentArticles('School/Course_(2026)', 42)(dispatch, getState());

      const action = dispatch.mock.calls.map(call => call[0]).find(a => a.type === RECEIVE_STUDENT_ARTICLES);
      expect(action.data.course.articles).toEqual(page);
      expect(action.userId).toBe(42);
      expect(action.pageSize).toBe(500);
      expect(fetchWikidataLabelsForArticles).toHaveBeenCalledWith(page, dispatch);
    });

    it('dispatches API_FAIL when the request fails', async () => {
      mockResponse({}, false, 500);
      const dispatch = jest.fn();
      await fetchStudentArticles('School/Course_(2026)', 42)(dispatch, getState());

      const types = dispatch.mock.calls.map(call => call[0].type);
      expect(types).toContain(API_FAIL);
      expect(types).not.toContain(RECEIVE_STUDENT_ARTICLES);
    });
  });

  describe('fetchMoreStudentArticles', () => {
    it('asks for the page after the highest articles_course_id of that student', async () => {
      mockResponse({ course: { articles: [] } });
      await fetchMoreStudentArticles('School/Course_(2026)', 42)(
        jest.fn(), getState({ 42: { articles: rows([7, 3, 9]), limitReached: false } })
      );

      const url = global.fetch.mock.calls[0][0];
      expect(url).toContain('after_id=9');
      expect(url).toContain('user_id=42');
    });

    it('dispatches RECEIVE_MORE_STUDENT_ARTICLES with the student id', async () => {
      const page = rows([10, 11]);
      mockResponse({ course: { articles: page } });
      const dispatch = jest.fn();
      await fetchMoreStudentArticles('School/Course_(2026)', 42)(
        dispatch, getState({ 42: { articles: rows([1, 2]), limitReached: false } })
      );

      const action = dispatch.mock.calls.map(call => call[0]).find(a => a.type === RECEIVE_MORE_STUDENT_ARTICLES);
      expect(action.userId).toBe(42);
      expect(action.data.course.articles).toEqual(page);
    });
  });
});
