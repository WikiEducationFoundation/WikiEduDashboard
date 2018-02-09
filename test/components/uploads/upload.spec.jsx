import React from 'react';
import '../../testHelper';
import { shallow } from 'enzyme';
import Upload from '../../../app/assets/javascripts/components/uploads/upload';

describe('Upload', () => {
  const mockUpload = {
    id: 123,
    file_name: 'Paper prototype of website user interface, 2015-04-16.jpg',
    thumburl:
      'https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Paper_prototype_of_website_user_interface%2C_2015-04-16.jpg/640px-Paper_prototype_of_website_user_interface%2C_2015-04-16.jpg',
    url:
      'https://commons.wikimedia.org/wiki/File:Paper_prototype_of_website_user_interface,_2015-04-16.jpg',
    uploader: 'Ragesoss',
    uploaded_at: new Date().toISOString(),
    usage_count: 1,
    usages: 0
  };

  it('Should exist', () => {
    const renderedUpload = shallow(
      <Upload upload={mockUpload} linkUsername={true} />
    );

    expect(renderedUpload).to.exist;
  });

  it('Should render Upload details differently if usages is 0', () => {
    const renderedUpload = shallow(
      <Upload upload={mockUpload} linkUsername={true} />
    );
    const spans = renderedUpload.find('span');

    expect(spans.length).to.equal(1);
  });

  it('Should render Upload details differently if usages is > 0', () => {
    mockUpload.usages = 1;

    const renderedUpload = shallow(
      <Upload upload={mockUpload} linkUsername={true} />
    );
    const spans = renderedUpload.find('span');

    expect(spans.length).to.equal(3);
  });

  it('Should not have an ellipsis if file_name is less than 60 characters', () => {
    const renderedUpload = shallow(
      <Upload upload={mockUpload} linkUsername={true} />
    );
    const fileElement = renderedUpload
      .find('.desktop-only-tc')
      .first()
      .children()
      .text();

    expect(fileElement).to.not.include('…');
  });

  it('Should have an ellipsis if file_name is greater than 60 chatacters', () => {
    mockUpload.file_name =
      'Paper prototype of website user interface super cool, 2015-04-16.jpg';

    const renderedUpload = shallow(
      <Upload upload={mockUpload} linkUsername={true} />
    );
    const fileElement = renderedUpload
      .find('.desktop-only-tc')
      .first()
      .children()
      .text();
    expect(fileElement).to.include('…');
  });

  it('Should use the provided thumburl for the imageFile', () => {
    const renderedUpload = shallow(
      <Upload upload={mockUpload} linkUsername={true} />
    );
    const imageFile = renderedUpload.find('img').prop('src');

    expect(imageFile).to.equal(mockUpload.thumburl);
  });

  it('Should use a deleted image if upload.deleted is true', () => {
    mockUpload.deleted = true;

    const renderedUpload = shallow(
      <Upload upload={mockUpload} linkUsername={true} />
    );

    const imageFile = renderedUpload.find('img').prop('src');
    expect(imageFile).to.equal('/assets/images/deleted_image.svg');
  });

  it('Should render uploader differently if linkUsername is false', () => {
    const renderedUpload = shallow(
      <Upload upload={mockUpload} linkUsername={false} />
    );
    const uploader = renderedUpload
      .find('.desktop-only-tc')
      .at(1)
      .text();

    expect(uploader).to.equal(mockUpload.uploader);
  });

  it('Should render uploader differently if linkUsername is true', () => {
    const renderedUpload = shallow(
      <Upload upload={mockUpload} linkUsername={true} />
    );
    const uploader = renderedUpload
      .find('.desktop-only-tc')
      .at(1)
      .html();
    const expected =
      '<td class="desktop-only-tc"><a href="/users/Ragesoss">Ragesoss</a></td>';

    expect(uploader).to.equal(expected);
  });
});
