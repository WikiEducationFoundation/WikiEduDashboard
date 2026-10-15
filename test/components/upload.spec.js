import '../testHelper';
import React from 'react';
import { createRoot } from 'react-dom/client';
import { act } from 'react-dom/test-utils';
import Upload from '../../app/assets/javascripts/components/uploads/upload.jsx';
import { GALLERY_VIEW, LIST_VIEW } from '../../app/assets/javascripts/constants';

global.IS_REACT_ACT_ENVIRONMENT = true;

describe('Upload component', () => {
  let container;
  let root;

  const baseUpload = {
    id: 1,
    file_name: 'test_file.jpg',
    uploader: 'TestUser',
    uploaded_at: '2026-01-01T00:00:00Z',
    usage_count: 3,
    url: 'https://commons.wikimedia.org/wiki/File:test_file.jpg',
    thumburl: 'https://upload.wikimedia.org/thumb/test.jpg',
    thumbwidth: 640,
    thumbheight: 480,
    deleted: false
  };

  beforeEach(() => {
    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
  });

  afterEach(() => {
    act(() => {
      root.unmount();
    });
    container.remove();
  });

  test('renders with initial thumb dimensions and thumburl in gallery view', () => {
    act(() => {
      root.render(<Upload upload={baseUpload} view={GALLERY_VIEW} linkUsername={false} />);
    });
    const img = container.querySelector('img');
    expect(img).not.toBeNull();
    expect(img.getAttribute('src')).toBe('https://upload.wikimedia.org/thumb/test.jpg');
    // Flex grow calculated from 640x480: (640 * 250) / 480 = 333.333
    const tile = container.querySelector('.upload');
    expect(tile.style.flexGrow).toMatch(/^333\.333/);
  });

  test('uses missing image placeholder when upload is deleted', () => {
    const deletedUpload = { ...baseUpload, deleted: true };
    act(() => {
      root.render(<Upload upload={deletedUpload} view={GALLERY_VIEW} linkUsername={false} />);
    });
    const img = container.querySelector('img');
    expect(img.getAttribute('src')).toBe('/assets/images/deleted_image.svg');
  });

  test('uses missing image placeholder when thumburl is missing', () => {
    const missingThumb = { ...baseUpload, thumburl: null };
    act(() => {
      root.render(<Upload upload={missingThumb} view={GALLERY_VIEW} linkUsername={false} />);
    });
    const img = container.querySelector('img');
    expect(img.getAttribute('src')).toBe('/assets/images/deleted_image.svg');
  });

  test('renders list view without error', () => {
    act(() => {
      root.render(
        <table>
          <tbody>
            <Upload upload={baseUpload} view={LIST_VIEW} linkUsername={true} />
          </tbody>
        </table>
      );
    });
    expect(container.querySelector('.upload')).not.toBeNull();
    expect(container.textContent).toContain('TestUser');
    expect(container.textContent).toContain('test_file.jpg');
  });
});
