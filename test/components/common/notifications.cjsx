require '../../testHelper'
McFly = require 'mcfly'
Flux = new McFly()
dispatcher = Flux.dispatcher
rewire = require 'rewire'

describe 'Notifications', ->
  Notifications = rewire '../../../app/assets/javascripts/components/common/notifications.cjsx'

  it 'renders', ->

    rendered = ReactTestUtils.renderIntoDocument(
      <Notifications />
    )

    expect(rendered).to.exist

  it 'updates via API_FAIL action and removes via close', (done) ->

    rendered = ReactTestUtils.renderIntoDocument(
      <div>
        <Notifications />
      </div>
    )

    console.log rendered.innerHTML

    rows = rendered.querySelectorAll '.notice'
    expect(rows.length).to.eq 0

    notification =
      responseJSON:
        error: 'Test error'

    dispatcher.dispatch
      actionType: 'API_FAIL'
      data: notification

    rows = rendered.querySelectorAll '.notice'
    expect(rows.length).to.eq 1

    close = rendered.querySelector 'svg'
    Simulate.click(close)

    setImmediate(() ->
      rows = rendered.querySelectorAll '.notice'
      expect(rows.length).to.eq 0
      done()
    )
