import { mount } from 'enzyme';
import React from 'react';

import '../../testHelper';
import Modal from '../../../app/assets/javascripts/components/common/modal.jsx';

describe('Modal', () => {
  const wrapper = mount(
    <Modal modalClass="foo">
      <h3>bar</h3>
    </Modal>
    );

  it('renders its children with the modalClass', () => {
    expect(wrapper.text()).toEqual('bar');
    expect(wrapper.find('div.wizard.active.foo')).toHaveLength(1);
  });

  it('adds modal-open class to the body', () => {
    expect(document.body.className).toEqual('modal-open');
  });

  it('removes the modal-open when it unmounts', () => {
    wrapper.unmount();
    expect(document.body.className).toEqual('');
  });
});
