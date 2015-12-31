require '../../testHelper'
McFly = require 'mcfly'
Flux = new McFly()
rewire = require 'rewire'

describe 'TagButton', ->
  TagButton = rewire '../../../app/assets/javascripts/components/overview/tag_button'
  TagStore = rewire '../../../app/assets/javascripts/stores/tag_store'

  it 'renders a plus button', ->
    TestButton = ReactTestUtils.renderIntoDocument(
      <TagButton
        tags=[]
        show=true
      />
    )
    renderedButton = ReactTestUtils.findRenderedDOMComponentWithClass(TestButton, 'plus')
