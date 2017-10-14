import "../testHelper";
import reducer from "../../app/assets/javascripts/reducers/user_courses.js";
import { RECEIVE_USER_COURSES } from "../../app/assets/javascripts/constants";

describe("Did you know reducer menu reducer", () => {
  it("should return the initial state", () => {
    const initialState = {
      userCourses: []
    };

    expect(reducer(undefined, {})).to.deep.eq(initialState);
  });

  it("should update array with new user course", () => {
    const newCourses = [{ id: 1, title: "Test - Test (test-1)" }];
    const oldCourses = [{ id: 2, title: "Test - Test (test-2)" }];

    const initialState = {
      userCourses: oldCourses
    };

    expect(
      reducer(initialState, {
        type: RECEIVE_USER_COURSES,
        payload: {
          data: { courses: newCourses }
        }
      })
    ).to.deep.eq({
      userCourses: newCourses
    });
  });
});
