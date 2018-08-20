import article_details from '../../app/assets/javascripts/reducers/article_details';
import { RECEIVE_ARTICLE_DETAILS } from "../../app/assets/javascripts/constants/article_details";
import '../testHelper';

describe('article_details reducer', () => {

  it('Should return initial state if no action type matches', () => {
    const mockAction = {
      type: 'NO_TYPE'
    };
    const initialState = {};

    const result = article_details(undefined, mockAction);
    expect(result).to.deep.eq(initialState);
  });

  it('should reutrn a new state if action type is RECEIVE_ARTICLE_DETAILS', () => {
    const mockAction = {
      type: RECEIVE_ARTICLE_DETAILS,
      articleId: 586,
      data: {
        article_details: 'best article ever'
      }
    };
    const expectedState = {
      586: 'best article ever'
    };
    expect(article_details(undefined, mockAction)).to.deep.eq(expectedState);
  });
});
