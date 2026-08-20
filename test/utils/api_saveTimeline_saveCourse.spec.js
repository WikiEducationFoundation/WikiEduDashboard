import '../testHelper';
import API from '../../app/assets/javascripts/utils/api';
import * as requestModule from '../../app/assets/javascripts/utils/request';

describe('API.saveTimeline', () => {
  afterEach(() => {
    if (requestModule.default.restore) requestModule.default.restore();
    delete global.Sentry;
    jest.restoreAllMocks();
  });

  test('resolves with the parsed JSON on success', async () => {
    sinon.stub(requestModule, 'default').resolves({
      ok: true,
      json: () => Promise.resolve({ weeks: [] }),
    });

    const result = await API.saveTimeline(42, { weeks: [] });

    expect(result).toEqual({ weeks: [] });
  });

  test('on failure, logs to console, reports to Sentry, and rethrows an ApiError', async () => {
    sinon.stub(requestModule, 'default').resolves({
      ok: false,
      status: 422,
      statusText: 'Unprocessable Entity',
      text: () => Promise.resolve('{"error":"conflict"}'),
    });
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
    global.Sentry = { captureMessage: jest.fn() };

    await expect(API.saveTimeline(42, { weeks: [] })).rejects.toMatchObject({
      name: 'ApiError',
      status: 422,
      statusText: 'Unprocessable Entity',
      responseText: '{"error":"conflict"}',
    });

    expect(consoleError).toHaveBeenCalledWith('Couldn\'t save timeline!');
    expect(global.Sentry.captureMessage).toHaveBeenCalledWith('saveTimeline failed', {
      level: 'error',
      extra: expect.objectContaining({
        type: 'POST',
        obj: '{"error":"conflict"}',
        status: 'Unprocessable Entity',
      }),
    });
  });

  test('on failure, still rethrows the original ApiError when Sentry is not defined', async () => {
    sinon.stub(requestModule, 'default').resolves({
      ok: false,
      status: 500,
      statusText: 'Server Error',
      text: () => Promise.resolve(''),
    });
    jest.spyOn(console, 'error').mockImplementation(() => {});

    // Asserting on the specific ApiError (not just `rejects.toBeInstanceOf(Error)`)
    // matters here: a ReferenceError from an unguarded `Sentry.captureMessage` call
    // is also an instance of Error, so a looser assertion wouldn't catch a missing
    // `typeof Sentry !== 'undefined'` guard.
    await expect(API.saveTimeline(42, { weeks: [] })).rejects.toMatchObject({
      name: 'ApiError',
      status: 500,
      statusText: 'Server Error',
    });
  });
});

describe('API.saveCourse', () => {
  afterEach(() => {
    if (requestModule.default.restore) requestModule.default.restore();
    delete global.Sentry;
    jest.restoreAllMocks();
  });

  test('resolves with the parsed JSON on success', async () => {
    sinon.stub(requestModule, 'default').resolves({
      ok: true,
      json: () => Promise.resolve({ id: 1 }),
    });

    const result = await API.saveCourse({ course: { title: 'Test' } }, 1);

    expect(result).toEqual({ id: 1 });
  });

  test('on failure, reports to Sentry and rethrows an ApiError', async () => {
    sinon.stub(requestModule, 'default').resolves({
      ok: false,
      status: 400,
      statusText: 'Bad Request',
      text: () => Promise.resolve('nope'),
    });
    global.Sentry = { captureMessage: jest.fn() };

    await expect(API.saveCourse({ course: {} }, 1)).rejects.toMatchObject({
      name: 'ApiError',
      status: 400,
      statusText: 'Bad Request',
      responseText: 'nope',
    });

    expect(global.Sentry.captureMessage).toHaveBeenCalledWith('saveCourse failed', {
      level: 'error',
      extra: expect.objectContaining({
        type: 'PUT',
        obj: 'nope',
        status: 'Bad Request',
      }),
    });
  });
});
