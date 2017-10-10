import "../testHelper";
import reducer from "../../app/assets/javascripts/reducers/did_you_know.js";
import { RECEIVE_DYK } from "../../app/assets/javascripts/constants";

describe("Did you know reducer menu reducer", () => {
  it("should return the initial state", () => {
    const initialState = {
      articles: [],
      loading: true
    };

    expect(reducer(undefined, {})).to.deep.eq(initialState);
  });

  it("should update array with new did you know articles", () => {
    const newArticles = [{ title: "new-1" }, { title: "new-2" }];
    const oldArticles = [{ title: "old-1" }, { title: "old-2" }];

    const initialState = {
      articles: oldArticles,
      loading: true
    };

    expect(
      reducer(initialState, {
        type: RECEIVE_DYK,
        payload: {
          data: { articles: newArticles }
        }
      })
    ).to.deep.eq({
      articles: newArticles,
      loading: false
    });
  });
});
