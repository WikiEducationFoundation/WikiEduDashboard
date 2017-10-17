import '../../testHelper';

import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';

import UploadTable from '../../../app/assets/javascripts/components/activity/upload_table.jsx';

describe('UploadTable', () => {
  const uploads = [{
    id: 123,
    file_name: 'Paper prototype of website user interface, 2015-04-16.jpg',
    thumburl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Paper_prototype_of_website_user_interface%2C_2015-04-16.jpg/640px-Paper_prototype_of_website_user_interface%2C_2015-04-16.jpg',
    url: 'https://commons.wikimedia.org/wiki/File:Paper_prototype_of_website_user_interface,_2015-04-16.jpg',
    uploader: 'Ragesoss',
    uploaded_at: new Date().toISOString(),
    usage_count: 1
  }, {
    id: 456,
    file_name: 'Young man in bar, cross processed.JPG',
    thumburl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Young_man_in_bar%2C_cross_processed.JPG/640px-Young_man_in_bar%2C_cross_processed.JPG',
    url: 'https://commons.wikimedia.org/wiki/File:Young_man_in_bar,_cross_processed.JPG',
    uploader: 'Ragesoss',
    uploaded_at: new Date().toISOString(),
    usage_count: 2
  }];

  const headers = [
    { title: 'Image', key: 'image' },
    { title: 'File Name', key: 'file_name' },
    { title: 'Uploaded By', key: 'username' },
    { title: 'Usage Count', key: 'usage_count' },
    { title: 'Date/Time', key: 'date' },
  ];

  it('shows loading when loading attribute is true', () => {
    const TestTable = ReactTestUtils.renderIntoDocument(
      <div>
        <UploadTable
          loading={true}
        />
      </div>
    );

    const loading = TestTable.querySelector('.loading');
    expect(loading).to.exist;
  });

  it('renders headers', () => {
    const TestTable = ReactTestUtils.renderIntoDocument(
      <div>
        <UploadTable
          loading={false}
          uploads={uploads}
          headers={headers}
        />
      </div>
    );

    const headerElements = TestTable.querySelectorAll('th');
    expect(headerElements.length).to.eq(6);
  });

  it('renders activities', () => {
    const TestTable = ReactTestUtils.renderIntoDocument(
      <div>
        <UploadTable
          loading={false}
          uploads={uploads}
          headers={headers}
        />
      </div>
    );

    const rowElements = TestTable.querySelectorAll('tr.upload');
    expect(rowElements.length).to.eq(2);
  });
});
