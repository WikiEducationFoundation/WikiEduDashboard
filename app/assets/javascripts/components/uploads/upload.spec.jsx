import React from 'react';
import renderer from 'react-test-renderer';
import Upload from './upload';
import { GALLERY_VIEW } from '../../constants';

describe('Upload', () => {
  beforeAll(() => {
    global.Image = class {
      constructor() {
        this.width = 0;
        this.height = 0;
        this.onload = null;
      }
      set src(value) {
        if (typeof this.onload === 'function') {
          this.onload();
        }
      }
    };

    global.I18n.translations = {
      en: {
        uploads: {
          usage_count_gallery_tile: {
            one: 'Used in %{usage_count} article',
            other: 'Used in %{usage_count} articles'
          },
          uploaded_by: 'Uploaded By',
          uploaded_on: 'Uploaded On'
        }
      }
    };
    global.I18n.locale = 'en';
  });

  it('renders singular upload usage as "Used in 1 article"', () => {
    const upload = {
      file_name: 'TestFile.png',
      uploader: 'test_user',
      usage_count: 1,
      url: 'https://commons.wikimedia.org/wiki/File:TestFile.png',
      thumburl: 'https://example.com/test.png',
      uploaded_at: '2020-01-01T00:00:00Z',
      deleted: false,
      credit: ''
    };

    const component = renderer.create(<Upload upload={upload} view={GALLERY_VIEW} />);
    const tree = component.toJSON();
    expect(JSON.stringify(tree)).toContain('Used in 1 article');
  });
});
