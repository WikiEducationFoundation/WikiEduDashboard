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

  it 'does not render block if empty', ->
    TestMilestones.setState(weeks: [week2])
    expect(TestMilestones.render()).to.equal(null)
