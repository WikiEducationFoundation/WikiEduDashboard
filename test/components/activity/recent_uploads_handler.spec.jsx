import React from 'react';
import { mount } from 'enzyme';
import ReactTestUtils from 'react-dom/test-utils';
import '../../testHelper';
import UploadList from '../../../app/assets/javascripts/components/uploads/upload_list.jsx';
import { RecentUploadsHandlerBase } from '../../../app/assets/javascripts/components/activity/recent_uploads_handler.jsx';


describe('RecentUploadsHandler', () => {
  it('fetches recent uploads', () => {
    const spy = sinon.spy();

    mount(<RecentUploadsHandlerBase fetchRecentUploads={spy} uploads={[]} />);

    // called once when mounted
    expect(spy.callCount).toEqual(1);
  });
});


describe('UploadList', () => {
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


  it('renders activities', () => {
    const TestTable = ReactTestUtils.renderIntoDocument(
      <div>
        <UploadList
          uploads={uploads}
        />
      </div>
    );

    const bodyElement = TestTable.querySelectorAll('div.upload');
    expect(bodyElement).toExist;
  });
});
