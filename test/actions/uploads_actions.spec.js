import { setUploadMetadata } from '../../app/assets/javascripts/actions/uploads_actions';
import { SET_UPLOAD_METADATA } from '../../app/assets/javascripts/constants';

jest.mock('../../app/assets/javascripts/utils/log_error_message');

describe('setUploadMetadata', () => {
  const originalFetch = global.fetch;

  beforeEach(() => {
    global.fetch = jest.fn(() => Promise.reject(new Error('Network error')));
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('sends the IDs of every requested upload across all batches when fetching fails', async () => {
    const uploads = Array.from({ length: 30 }, (_, i) => ({ id: i + 1 }));
    const dispatch = jest.fn();

    await setUploadMetadata(uploads)(dispatch);

    expect(global.fetch).toHaveBeenCalledTimes(2);
    expect(dispatch).toHaveBeenCalledWith(expect.objectContaining({
      type: SET_UPLOAD_METADATA,
      requestedIds: uploads.map(upload => upload.id),
    }));
  });
});
