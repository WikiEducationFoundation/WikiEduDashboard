require '../../testHelper'
rewire = require 'rewire'

Milestones  = rewire '../../../app/assets/javascripts/components/overview/milestones'

describe 'Milestones', ->
  course = { string_prefix: 'courses' }
  block = { id: 1, kind: 2, content: 'Tacos are great' }
  week = { order: 1, blocks: [block] }
  week2 = { order: 2, blocks: [] }

  TestMilestones = ReactTestUtils.renderIntoDocument(
    <Milestones
      course={course}
    />
  )

  it 'renders block content in a <p> tag', ->
    TestMilestones.setState(weeks: [week])
    milestones = ReactTestUtils.findRenderedDOMComponentWithClass(TestMilestones, 'milestones')
    expect(milestones.innerHTML).to.include('<p>Tacos are great</p>')

  it 'renders an empty message if there are no blocks', ->
    TestMilestones.setState(weeks: [week2])
    milestones = ReactTestUtils.findRenderedDOMComponentWithClass(TestMilestones, 'milestones')
    # fails  when run in isolation with the `mocha` bin,
    # but passes with `gulp js_coverage` because of I18n issues
    expect(milestones.innerHTML).to.include('This course does not currently have any milestones.')
