import React from 'react';
import ReactTestUtils from 'react-dom/test-utils';
import { shallow, mount } from 'enzyme';

import '../../testHelper';

import UserUploads from '../../../app/assets/javascripts/components/user_profiles/user_uploads.jsx';

describe('UserUploads', () => {
  it('should match the snapshot with no uploads', () => {
    const message = 'This user has not contributed any images or other media files to Wikimedia Commons.';
    const mockUploads = [];
    const wrapper = shallow(<UserUploads courses={courses} uploads={mockUploads} />);
    expect(wrapper.find('UploadList').length).to.equal(0);
  });

  it('should match the snapshot with uploads', () => {

    const mockUploads = [{ id: 1 }, { id: 2 }];
    const wrapper = shallow(<UserUploads uploads={mockUploads} />);

    expect(wrapper.find('UploadList').length).to.equal(1);
  });
});
