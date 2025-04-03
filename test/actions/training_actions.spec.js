import configureMockStore from "redux-mock-store";
import thunk from "redux-thunk";
import sinon from "sinon";
import "../testHelper";
import {
  RECEIVE_ALL_TRAINING_MODULES,
  RECEIVE_TRAINING_MODULE,
  EXERCISE_COMPLETION_UPDATE,
  API_FAIL,
} from "../../app/assets/javascripts/constants";
import {
  fetchAllTrainingModules,
  fetchTrainingModule,
  setExerciseModuleComplete,
  setExerciseModuleIncomplete,
} from "../../app/assets/javascripts/actions/training_actions";
import * as requestModule from "../../app/assets/javascripts/utils/request";

const middlewares = [thunk];
const mockStore = configureMockStore(middlewares);

describe("Training Module Actions", () => {
  beforeEach(() => {
    sinon.stub(requestModule, "default");
  });

  afterEach(() => {
    requestModule.default.restore();
  });

  test("dispatches RECEIVE_ALL_TRAINING_MODULES on successful fetchAllTrainingModules", () => {
    const mockData = [{ id: 1, title: "Module 1" }];
    requestModule.default.resolves({
      ok: true,
      json: sinon.fake.returns(mockData),
    });

    const expectedActions = [
      { type: RECEIVE_ALL_TRAINING_MODULES, data: mockData },
    ];

    const store = mockStore({});
    return store.dispatch(fetchAllTrainingModules()).then(() => {
      expect(store.getActions()).toEqual(expectedActions);
    });
  });

  test("dispatches API_FAIL on failed fetchAllTrainingModules", () => {
    requestModule.default.rejects(new Error("API error"));

    const expectedActions = [{ type: API_FAIL, data: new Error("API error") }];

    const store = mockStore({});
    return store.dispatch(fetchAllTrainingModules()).then(() => {
      expect(store.getActions()).toEqual(expectedActions);
    });
  });

  test("dispatches RECEIVE_TRAINING_MODULE on successful fetchTrainingModule", () => {
    const mockData = { training_module: { slides: [{ slug: "slide-1" }] } };
    requestModule.default.resolves({
      ok: true,
      json: sinon.fake.returns(mockData),
    });

    const expectedActions = [
      {
        type: RECEIVE_TRAINING_MODULE,
        data: { ...mockData, slide: "slide-1", valid: true },
      },
    ];

    const store = mockStore({});
    return store
      .dispatch(fetchTrainingModule({ slide_id: "slide-1" }))
      .then(() => {
        expect(store.getActions()).toEqual(expectedActions);
      });
  });

  test("dispatches API_FAIL on failed fetchTrainingModule", () => {
    requestModule.default.rejects(new Error("API error"));

    const expectedActions = [{ type: API_FAIL, data: new Error("API error") }];

    const store = mockStore({});
    return store
      .dispatch(fetchTrainingModule({ slide_id: "slide-1" }))
      .then(() => {
        expect(store.getActions()).toEqual(expectedActions);
      });
  });

  test("dispatches EXERCISE_COMPLETION_UPDATE on successful setExerciseModuleComplete", () => {
    const mockData = { status: "complete" };
    requestModule.default.resolves({
      ok: true,
      json: sinon.fake.resolves(mockData),
    });

    const expectedActions = [
      { type: EXERCISE_COMPLETION_UPDATE, data: mockData },
    ];

    const store = mockStore({});
    return store.dispatch(setExerciseModuleComplete(1, 2)).then(() => {
      expect(store.getActions()).toEqual(expectedActions);
    });
  });

  test("dispatches API_FAIL on failed setExerciseModuleIncomplete", () => {
    requestModule.default.rejects(new Error("API error"));

    const expectedActions = [{ type: API_FAIL, data: new Error("API error") }];

    const store = mockStore({});
    return store.dispatch(setExerciseModuleIncomplete(1, 2)).then(() => {
      expect(store.getActions()).toEqual(expectedActions);
    });
  });
});
