import '../testHelper';
import { ensureOk, ApiError } from '../../app/assets/javascripts/utils/request';

describe('ensureOk', () => {
  test('resolves with the response unchanged when the response is ok', async () => {
    const response = { ok: true, status: 200 };
    await expect(ensureOk(response)).resolves.toBe(response);
  });

  test('throws an ApiError carrying status/statusText/url/responseText when not ok', async () => {
    const response = {
      ok: false,
      status: 403,
      statusText: 'Forbidden',
      url: 'https://www.wikidata.org/w/api.php',
      text: () => Promise.resolve('{"error":"blocked"}'),
    };

    await expect(ensureOk(response)).rejects.toMatchObject({
      name: 'ApiError',
      message: 'Forbidden',
      status: 403,
      statusText: 'Forbidden',
      url: 'https://www.wikidata.org/w/api.php',
      responseText: '{"error":"blocked"}',
    });
  });

  test('thrown ApiError is a real Error with a stack trace, unlike a raw Response', async () => {
    const response = { ok: false, status: 500, statusText: '', text: () => Promise.resolve('') };

    await expect(ensureOk(response)).rejects.toBeInstanceOf(Error);
    try {
      await ensureOk(response);
      throw new Error('expected ensureOk to throw');
    } catch (error) {
      expect(error).toBeInstanceOf(ApiError);
      expect(error.message).toBe('Request failed with status 500');
      expect(String(error)).not.toBe('[object Response]');
      expect(error.stack).toBeDefined();
    }
  });

  test('falls back to an empty responseText if response.text() itself rejects', async () => {
    const response = {
      ok: false,
      status: 500,
      statusText: 'Server Error',
      text: () => Promise.reject(new Error('stream already read')),
    };

    await expect(ensureOk(response)).rejects.toMatchObject({ responseText: '' });
  });

  test('an optional prefix is passed through to error logging without changing the thrown error', async () => {
    const response = { ok: false, status: 400, statusText: 'Bad Request', text: () => Promise.resolve('') };

    await expect(ensureOk(response, 'Could not do the thing: ')).rejects.toMatchObject({
      status: 400,
      statusText: 'Bad Request',
    });
  });
});
