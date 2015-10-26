require '../../specHelper'

describe 'Modal', ->

  Modal = require '../../../app/assets/javascripts/components/common/modal'
  TestModal = ReactTestUtils.renderIntoDocument(
    <Modal modalClass='foo'>
      <h3>bar</h3>
    </Modal>
  )

  it 'renders its children with the modalClass', ->
    modalContent = ReactTestUtils.findRenderedDOMComponentWithTag(TestModal, 'div')
    modalContent.getDOMNode().textContent.should.equal 'bar'
    modalContent.getDOMNode().className.should.equal 'wizard active foo'

  it 'adds modal-open class to the body', ->
    document.body.className.should.equal 'modal-open'

  it 'removes the modal-open when it unmounts', ->
    TestModal.componentWillUnmount()
    document.body.className.should.equal ''
