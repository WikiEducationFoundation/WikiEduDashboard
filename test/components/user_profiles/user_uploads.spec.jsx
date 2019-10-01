import React from 'react';
import { shallow } from 'enzyme';
import '../../testHelper';
import UserUploads from '../../../app/assets/javascripts/components/user_profiles/user_uploads.jsx';

describe('UserUploads', () => {
  it('should not render the upload list if there are no user uploads', () => {
    const mockUploads = [];
    const wrapper = shallow(<UserUploads uploads={mockUploads} />);
    expect(wrapper.find('UploadList').length).toEqual(0);
  });

  it('should render the upload list component if there are user uploads', () => {
    const mockUploads = [{ id: 1 }, { id: 2 }];
    const wrapper = shallow(<UserUploads uploads={mockUploads} />);
    expect(wrapper.find('UploadList').length).toEqual(1);
  });
});
