import { useDispatch } from 'react-redux';
import ProfileDownloadButtons from '../../app/assets/javascripts/components/user_profiles/profile_download_buttons';

jest.mock('react-redux', () => ({ useDispatch: jest.fn() }));

describe('ProfileDownloadButtons', () => {
  test.each(['csv', 'json'])('queues %s in notifications without downloading automatically', (format) => {
    const dispatch = jest.fn();
    useDispatch.mockReturnValue(dispatch);
    const click = jest.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => {});
    const buttons = ProfileDownloadButtons({
      username: 'Example',
      section: 'statistics',
      data: { articles: [] }
    });

    buttons.props.children[format === 'csv' ? 0 : 1].props.onClick();

    const ready = dispatch.mock.calls
      .map(([action]) => action)
      .find(action => action.changes?.status === 'ready');
    expect(ready.changes.downloadUrl).toMatch(/^data:/);
    expect(ready.changes.filename).toBe(`Example_statistics.${format}`);
    expect(click).not.toHaveBeenCalled();
    const notification = dispatch.mock.calls
      .map(([action]) => action)
      .find(action => action.notification);
    expect(notification.notification).toEqual({
      message: I18n.t('downloads.available_in_bell'), type: 'success', closable: true
    });
    click.mockRestore();
  });
});
