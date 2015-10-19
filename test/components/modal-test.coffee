require('testdom')('<html><body></body></html>')

jsdom = require 'mocha-jsdom'
React = require 'react/addons'

describe 'Modal', ->
  jsdom( skipWindowCheck: true )

  it 'adds the modal-open class', ->
    Modal = require '../../app/assets/javascripts/components/common/modal'
    TestUtils = React.addons.TestUtils
    # TestModal = TestUtils.renderIntoDocument(
    #   <Modal
    #     modalClass='foo'
    #     children=[]
    #   />
    # )
