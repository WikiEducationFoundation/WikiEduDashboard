import '../../testHelper';
import React from 'react';
import ReactDOM from 'react-dom';
import ReactTestUtils from 'react-dom/test-utils';
import Modal from '../../../app/assets/javascripts/components/common/modal.jsx';

describe('Modal', () => {
  const TestModal = ReactTestUtils.renderIntoDocument(
    <Modal modalClass="foo">
      <h3>bar</h3>
    </Modal>
  );

  it('renders its children with the modalClass', () => {
    const modalContent = ReactTestUtils.findRenderedDOMComponentWithTag(TestModal, 'div');
    const content = ReactDOM.findDOMNode(modalContent);
    expect(content.textContent).to.eq('bar');
    expect(content.className).to.eq('wizard active foo');
  });

  it('adds modal-open class to the body', () => {
    expect(document.body.className).to.eq('modal-open');
  });

  it('removes the modal-open when it unmounts', () => {
    TestModal.componentWillUnmount();
    expect(document.body.className).to.eq('');
  });
});
