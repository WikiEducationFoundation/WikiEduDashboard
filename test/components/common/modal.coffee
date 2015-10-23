require('testdom')('<html><body></body></html>')
global.$ = require 'jquery'

jsdom = require 'mocha-jsdom'
React = require 'react/addons'

describe 'Modal', ->
  jsdom( skipWindowCheck: true )

  Modal = require '../../../app/assets/javascripts/components/common/modal'
  TestUtils = React.addons.TestUtils
  TestModal = TestUtils.renderIntoDocument(
    <Modal modalClass='foo'>
      <h3>bar</h3>
    </Modal>
  )

  it 'renders its children with the modalClass', ->
    modalContent = TestUtils.findRenderedDOMComponentWithTag(TestModal, 'div')
    modalContent.getDOMNode().textContent.should.equal 'bar'
    modalContent.getDOMNode().className.should.equal 'wizard active foo'

  it 'adds modal-open class to the body', ->
    document.body.className.should.equal 'modal-open'

  it 'removes the modal-open when it unmounts', ->
    TestModal.componentWillUnmount()
    document.body.className.should.equal ''
