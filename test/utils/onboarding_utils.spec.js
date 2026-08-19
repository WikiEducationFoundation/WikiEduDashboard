import '../testHelper';
import OnboardAPI from '../../app/assets/javascripts/utils/onboarding_utils';
import * as requestModule from '../../app/assets/javascripts/utils/request';

describe('OnboardAPI', () => {
  afterEach(() => {
    if (requestModule.default.restore) requestModule.default.restore();
  });

  describe('.onboard()', () => {
    test('resolves with the response text on success', async () => {
      sinon.stub(requestModule, 'default').resolves({
        ok: true,
        text: () => Promise.resolve('ok'),
      });

      expect(await OnboardAPI.onboard({ real_name: 'Test' })).toBe('ok');
    });

    test('rejects with a real Error (not a bare string) on failure', async () => {
      sinon.stub(requestModule, 'default').resolves({
        ok: false,
        status: 422,
        statusText: 'Unprocessable Entity',
        text: () => Promise.resolve('{"error":"invalid"}'),
      });

      await expect(OnboardAPI.onboard({ real_name: 'Test' })).rejects.toMatchObject({
        name: 'ApiError',
        status: 422,
        responseText: '{"error":"invalid"}',
      });
    });
  });

  describe('.supplement()', () => {
    test('resolves with the response text on success', async () => {
      sinon.stub(requestModule, 'default').resolves({
        ok: true,
        text: () => Promise.resolve('ok'),
      });

      expect(await OnboardAPI.supplement({ heardFrom: 'friend' })).toBe('ok');
    });

    test('rejects with a real Error (not a bare string) on failure', async () => {
      sinon.stub(requestModule, 'default').resolves({
        ok: false,
        status: 500,
        statusText: 'Server Error',
        text: () => Promise.resolve(''),
      });

      await expect(OnboardAPI.supplement({ heardFrom: 'friend' })).rejects.toBeInstanceOf(Error);
    });
  });
});
