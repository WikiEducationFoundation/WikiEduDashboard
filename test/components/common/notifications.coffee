require '../../testHelper'
McFly = require 'mcfly'
Flux = new McFly()
dispatcher = Flux.dispatcher
rewire = require 'rewire'

describe 'Notifications', ->
  Notifications = rewire '../../../app/assets/javascripts/components/common/notifications'

  it 'renders', ->

    rendered = ReactTestUtils.renderIntoDocument(
      <Notifications />
    )

    rendered.should.exist

  it 'updates via API_FAIL action and removes via close', (done) ->

    rendered = ReactTestUtils.renderIntoDocument(
      <Notifications />
    )

    notification =
      responseJSON:
        error: 'Test error'

    rows = ReactTestUtils.scryRenderedDOMComponentsWithClass rendered, 'notice'
    rows.length.should.equal 0

    dispatcher.dispatch
      actionType: 'API_FAIL'
      data: notification

    rows = ReactTestUtils.scryRenderedDOMComponentsWithClass rendered, 'notice'
    rows.length.should.equal 1

    close = ReactTestUtils.findRenderedDOMComponentWithTag rendered, 'svg'
    Simulate.click(close)

    setImmediate(() ->
      rows = ReactTestUtils.scryRenderedDOMComponentsWithClass rendered, 'notice'
      rows.length.should.equal 0
      done()
    )






