import { pollReportCsv } from '../../app/assets/javascripts/utils/csv_polling_utils';

describe('pollReportCsv', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
    jest.restoreAllMocks();
  });

  test('calls onReady when server responds with ready status', async () => {
    const readyData = { status: 'ready', url: '/reports/campaign.csv' };
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve(readyData)
    });

    const onReady = jest.fn();
    const onError = jest.fn();

    pollReportCsv('/campaigns/foo/courses', { onReady, onError });

    await Promise.resolve(); // drain microtask for initial fetch
    await Promise.resolve(); // drain json promise

    expect(global.fetch).toHaveBeenCalledWith('/campaigns/foo/courses', {
      headers: { Accept: 'application/json' },
      credentials: 'same-origin'
    });
    expect(onReady).toHaveBeenCalledWith(readyData);
    expect(onError).not.toHaveBeenCalled();
  });

  test('polls again when server responds with 202 generating', async () => {
    const generatingData = { status: 'generating' };
    const readyData = { status: 'ready', url: '/reports/campaign.csv' };

    global.fetch = jest.fn()
      .mockResolvedValueOnce({
        ok: true,
        status: 202,
        json: () => Promise.resolve(generatingData)
      })
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve(readyData)
      });

    const onReady = jest.fn();
    const onGenerating = jest.fn();
    const onError = jest.fn();

    pollReportCsv('/campaigns/foo/courses', { onReady, onGenerating, onError }, { intervalMs: 1000 });

    await Promise.resolve();
    await Promise.resolve();

    expect(onGenerating).toHaveBeenCalledWith(generatingData);
    expect(onReady).not.toHaveBeenCalled();

    // Fast-forward interval
    jest.advanceTimersByTime(1000);

    await Promise.resolve();
    await Promise.resolve();

    expect(onReady).toHaveBeenCalledWith(readyData);
    expect(global.fetch).toHaveBeenCalledTimes(2);
  });

  test('calls onError when server responds with 422', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 422,
      json: () => Promise.resolve({ error: 'Invalid dates' })
    });

    const onReady = jest.fn();
    const onError = jest.fn();

    pollReportCsv('/campaigns/foo/courses', { onReady, onError });

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(onError).toHaveBeenCalledWith('Invalid dates');
    expect(onReady).not.toHaveBeenCalled();
  });

  test('calls onError when max attempts is reached', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 202,
      json: () => Promise.resolve({ status: 'generating' })
    });

    const onReady = jest.fn();
    const onError = jest.fn();

    pollReportCsv(
      '/campaigns/foo/courses',
      { onReady, onError },
      { intervalMs: 500, maxAttempts: 2 }
    );

    // Attempt 1
    await Promise.resolve();
    await Promise.resolve();

    // Advance to attempt 2
    jest.advanceTimersByTime(500);
    await Promise.resolve();
    await Promise.resolve();

    expect(onError).toHaveBeenCalledWith('Timed out waiting for report generation');
    expect(onReady).not.toHaveBeenCalled();
  });

  test('cancel stops subsequent polls', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 202,
      json: () => Promise.resolve({ status: 'generating' })
    });

    const onReady = jest.fn();
    const onError = jest.fn();

    const cancel = pollReportCsv(
      '/campaigns/foo/courses',
      { onReady, onError },
      { intervalMs: 1000 }
    );

    await Promise.resolve();
    await Promise.resolve();
    expect(global.fetch).toHaveBeenCalledTimes(1);

    cancel();

    jest.advanceTimersByTime(2000);
    await Promise.resolve();

    expect(global.fetch).toHaveBeenCalledTimes(1);
    expect(onReady).not.toHaveBeenCalled();
  });
});
