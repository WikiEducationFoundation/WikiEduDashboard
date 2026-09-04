import '../../testHelper';
import { canUserCreateAccount } from '../../../app/assets/javascripts/components/util/helpers';

describe('canUserCreateAccount', () => {
  afterEach(() => {
    delete global.fetch;
  });

  test('returns true when the API reports no cancreateaccounterror', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ query: { userinfo: {} } }),
    });

    expect(await canUserCreateAccount()).toBe(true);
  });

  test('returns false when the API reports a cancreateaccounterror', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ query: { userinfo: { cancreateaccounterror: { code: 'blocked' } } } }),
    });

    expect(await canUserCreateAccount()).toBe(false);
  });

  test('fails open (returns true) on a network-level failure, e.g. Failed to fetch', async () => {
    global.fetch = jest.fn().mockRejectedValue(new TypeError('Failed to fetch'));

    await expect(canUserCreateAccount()).resolves.toBe(true);
  });

  test('fails open (returns true) when the response is not ok', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 500,
      statusText: 'Internal Server Error',
      text: () => Promise.resolve(''),
    });

    await expect(canUserCreateAccount()).resolves.toBe(true);
  });
});
