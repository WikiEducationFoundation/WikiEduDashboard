import "../testHelper";
import reducer from "../../app/assets/javascripts/reducers/did_you_know.js";
import { RECEIVE_DYK } from "../../app/assets/javascripts/constants";

describe("slider menu reducer", () => {
  it("should return the initial state", () => {
    expect(reducer(undefined, {})).toEqual(initialState);
  });

  it("should update array with new did you know articles", () => {
    const newArticles = [{ title: "new-1" }, { title: "new-2" }];
    const oldArticles = [{ title: "old-1" }, { title: "old-2" }];

    const initialState = new Map({
      articles: oldArticles
    });

    expect(
      reducer(initialState, {
        type: RECEIVE_DYK,
        payload: {
          articles: newArticles
        }
      })
    ).toEqual(
      fromJS({
        articles: newArticles
      })
    );
  });
});
