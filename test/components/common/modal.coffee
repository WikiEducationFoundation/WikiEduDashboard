require '../../testHelper'

describe 'Modal', ->

  Modal = require '../../../app/assets/javascripts/components/common/modal'
  TestModal = ReactTestUtils.renderIntoDocument(
    <Modal modalClass='foo'>
      <h3>bar</h3>
    </Modal>
  )

  it 'renders its children with the modalClass', ->
    modalContent = ReactTestUtils.findRenderedDOMComponentWithTag(TestModal, 'div')
    content = ReactDOM.findDOMNode(modalContent)
    content.textContent.should.equal 'bar'
    content.className.should.equal 'wizard active foo'

  it 'adds modal-open class to the body', ->
    document.body.className.should.equal 'modal-open'

  it 'removes the modal-open when it unmounts', ->
    TestModal.componentWillUnmount()
    document.body.className.should.equal ''
