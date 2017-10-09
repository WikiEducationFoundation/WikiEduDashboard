import '../../testHelper';
import React from 'react';
import Modal from '../../../app/assets/javascripts/components/common/modal.jsx';
import { mount } from 'enzyme';

describe('Modal', () => {
  const wrapper = mount(
    <Modal modalClass="foo">
      <h3>bar</h3>
    </Modal>
    );

  it('renders its children with the modalClass', () => {
    expect(wrapper.text()).to.equal('bar');
    expect(wrapper.find('div.wizard.active.foo')).to.have.length(1);
  });

  it('adds modal-open class to the body', () => {
    expect(document.body.className).to.eq('modal-open');
  });

  it('removes the modal-open when it unmounts', () => {
    wrapper.unmount();
    expect(document.body.className).to.eq('');
  });
});
