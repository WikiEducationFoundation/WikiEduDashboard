import deepFreeze from 'deep-freeze';
import article_details from '../../app/assets/javascripts/reducers/article_details';
import { RECEIVE_ARTICLE_DETAILS } from '../../app/assets/javascripts/constants/article_details';
import '../testHelper';

describe('article_details reducer', () => {
  test('Should return initial state if no action type matches', () => {
    const mockAction = {
      type: 'NO_TYPE'
    };
    const initialState = {};
    deepFreeze(initialState);

    const result = article_details(undefined, mockAction);
    expect(result).toEqual(initialState);
  });

  test(
    'should reutrn a new state if action type is RECEIVE_ARTICLE_DETAILS',
    () => {
      const mockAction = {
        type: RECEIVE_ARTICLE_DETAILS,
        articleId: 586,
        details: { detailsData: 'best article ever' },
        revisionRange: { revisionRangeData: 'more data' }
      };
      const expectedState = {
        586: {
          detailsData: 'best article ever',
          revisionRangeData: 'more data'
        }
      };
      expect(article_details(undefined, mockAction)).toEqual(expectedState);
    }
  );
});
