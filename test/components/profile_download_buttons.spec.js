import ProfileDownloadButtons from '../../app/assets/javascripts/components/user_profiles/profile_download_buttons';

describe('ProfileDownloadButtons', () => {
  beforeEach(() => {
    window.URL.createObjectURL = jest.fn().mockReturnValue('blob:test');
    window.URL.revokeObjectURL = jest.fn();
  });

  afterEach(() => {
    delete window.URL.createObjectURL;
    delete window.URL.revokeObjectURL;
  });

  test.each(['csv', 'json'])('triggers direct browser download for %s', (format) => {
    let clickedDownloadAttr = null;
    const clickSpy = jest.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function () {
      clickedDownloadAttr = this.getAttribute('download');
    });

    const buttons = ProfileDownloadButtons({
      username: 'Example?User',
      section: 'statistics',
      data: { articles: [] }
    });

    buttons.props.children[format === 'csv' ? 0 : 1].props.onClick();

    expect(clickSpy).toHaveBeenCalledTimes(1);
    expect(clickedDownloadAttr).toBe(`Example_User_statistics.${format}`);
    expect(window.URL.createObjectURL).toHaveBeenCalledTimes(1);
    expect(window.URL.revokeObjectURL).toHaveBeenCalledWith('blob:test');

    clickSpy.mockRestore();
  });
});
