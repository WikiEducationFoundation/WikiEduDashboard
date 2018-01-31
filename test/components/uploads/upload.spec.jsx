import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import '../../testHelper';
import Upload from '../../../app/assets/javascripts/components/uploads/upload';

describe('Upload', () => {
  const mockUpload = {
    id: 123,
    file_name: 'Paper prototype of website user interface, 2015-04-16.jpg',
    thumburl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Paper_prototype_of_website_user_interface%2C_2015-04-16.jpg/640px-Paper_prototype_of_website_user_interface%2C_2015-04-16.jpg',
    url: 'https://commons.wikimedia.org/wiki/File:Paper_prototype_of_website_user_interface,_2015-04-16.jpg',
    uploader: 'Ragesoss',
    uploaded_at: new Date().toISOString(),
    usage_count: 1,
    usages: 0
  };

  it('Should exist', () => {
    const renderedUpload = ReactTestUtils.renderIntoDocument(
      <div>
        <Upload
          upload={mockUpload}
          linkUsername={true}
        />
      </div>
    );

    expect(renderedUpload).to.exist;
  });

  it('Should render Upload details differently if usages is 0', () => {
    const renderedUpload = ReactTestUtils.renderIntoDocument(
      <div>
        <Upload
          upload={mockUpload}
          linkUsername={true}
        />
      </div>
    );
    const spans = renderedUpload.querySelectorAll('span');

    expect(spans.length).to.equal(1);
  });

  it('Should render Upload details differently if usages is > 0', () => {
    mockUpload.usages = 1;

    const renderedUpload = ReactTestUtils.renderIntoDocument(
      <div>
        <Upload
          upload={mockUpload}
          linkUsername={true}
        />
      </div>
    );
    const spans = renderedUpload.querySelectorAll('span');

    expect(spans.length).to.equal(3);
  });

  it('Should not have an ellipsis if file_name is less than 60 characters', () => {
    const renderedUpload = ReactTestUtils.renderIntoDocument(
      <div>
        <Upload
          upload={mockUpload}
          linkUsername={true}
        />
      </div>
    );
    const fileElement = renderedUpload.querySelectorAll('.desktop-only-tc')[0].children[0].innerHTML;
    expect(fileElement).to.not.include('…');
  });

  it('Should have an ellipsis if file_name is greater than 60 chatacters', () => {
    mockUpload.file_name = 'Paper prototype of website user interface super cool, 2015-04-16.jpg';

    const renderedUpload = ReactTestUtils.renderIntoDocument(
      <div>
        <Upload
          upload={mockUpload}
          linkUsername={true}
        />
      </div>
    );
    const fileElement = renderedUpload.querySelectorAll('.desktop-only-tc')[0].children[0].innerHTML;
    expect(fileElement).to.include('…');
  });

  it('Should use the provided thumburl for the imageFile', () => {
    const renderedUpload = ReactTestUtils.renderIntoDocument(
      <div>
        <Upload
          upload={mockUpload}
          linkUsername={true}
        />
      </div>
    );

    const imageFile = renderedUpload.querySelector('img').src;
    expect(imageFile).to.equal(mockUpload.thumburl);
  });

  it('Should use a deleted image if upload.deleted is true', () => {
    mockUpload.deleted = true;

    const renderedUpload = ReactTestUtils.renderIntoDocument(
      <div>
        <Upload
          upload={mockUpload}
          linkUsername={true}
        />
      </div>
    );

    const imageFile = renderedUpload.querySelector('img').src;
    expect(imageFile).to.equal('/assets/images/deleted_image.svg');
  });

  it('Should render uploader differently if linkUsername is false', () => {
    const renderedUpload = ReactTestUtils.renderIntoDocument(
      <div>
        <Upload
          upload={mockUpload}
          linkUsername={false}
        />
      </div>
    );
    const uploader = renderedUpload.querySelectorAll('.desktop-only-tc')[1].innerHTML;

    expect(uploader).to.equal(mockUpload.uploader);
  });

  it('Should render uploader differently if linkUsername is true', () => {
    const renderedUpload = ReactTestUtils.renderIntoDocument(
      <div>
        <Upload
          upload={mockUpload}
          linkUsername={true}
        />
      </div>
    );
    const uploader = renderedUpload.querySelectorAll('.desktop-only-tc')[1].innerHTML;
    const expected = '<a href="/users/Ragesoss">Ragesoss</a>';

    expect(uploader).to.equal(expected);
  });
});
