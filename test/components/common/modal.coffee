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
    expect(content.textContent).to.eq 'bar'
    expect(content.className).to.eq 'wizard active foo'

  it 'adds modal-open class to the body', ->
    expect(document.body.className).to.eq 'modal-open'

  it 'removes the modal-open when it unmounts', ->
    TestModal.componentWillUnmount()
    expect(document.body.className).to.eq ''
