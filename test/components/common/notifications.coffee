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

    expect(rendered).to.exist

  it 'updates via API_FAIL action and removes via close', (done) ->

    rendered = ReactTestUtils.renderIntoDocument(
      <Notifications />
    )

    notification =
      responseJSON:
        error: 'Test error'

    rows = ReactTestUtils.scryRenderedDOMComponentsWithClass rendered, 'notice'
    expect(rows.length).to.eq 0

    dispatcher.dispatch
      actionType: 'API_FAIL'
      data: notification

    rows = ReactTestUtils.scryRenderedDOMComponentsWithClass rendered, 'notice'
    expect(rows.length).to.eq 1

    close = ReactTestUtils.findRenderedDOMComponentWithTag rendered, 'svg'
    Simulate.click(close)

    setImmediate(() ->
      rows = ReactTestUtils.scryRenderedDOMComponentsWithClass rendered, 'notice'
      expect(rows.length).to.eq 0
      done()
    )






