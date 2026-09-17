import '../../testHelper';
import { canUserCreateAccount, selectUserByUsernameParam } from '../../../app/assets/javascripts/components/util/helpers';

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

describe('selectUserByUsernameParam', () => {
  const users = [
    { username: 'Grace Hopper' },
    { username: 'Mary Ann Smith' },
    { username: 'Solo' }
  ];

  test('matches a username given with spaces', () => {
    expect(selectUserByUsernameParam(users, 'Grace Hopper')).toBe(users[0]);
  });

  test('matches a one-space username given with an underscore', () => {
    expect(selectUserByUsernameParam(users, 'Grace_Hopper')).toBe(users[0]);
  });

  // Server-rendered links (mailers, the LTI roster) use the MediaWiki convention
  // of one underscore per space, so every underscore has to map back.
  test('matches a multi-word username given with several underscores', () => {
    expect(selectUserByUsernameParam(users, 'Mary_Ann_Smith')).toBe(users[1]);
  });

  test('returns undefined for a username nobody has', () => {
    expect(selectUserByUsernameParam(users, 'Nobody_Here')).toBeUndefined();
  });

  test('returns null when no param is given', () => {
    expect(selectUserByUsernameParam(users, undefined)).toBeNull();
  });
});
