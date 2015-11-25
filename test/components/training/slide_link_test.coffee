require '../../testHelper'
SlideLink = require '../../../app/assets/javascripts/training/components/slide_link'
TrainingSlideHandler = require '../../../app/assets/javascripts/training/components/training_slide_handler'
CustomUtils = require '../../customUtils'

describe 'SlideLink', ->
  TestLink = ReactTestUtils.renderIntoDocument(
    <TrainingSlideHandler
      loading=false
      params={ library_id: 'foo', module_id: 'bar', slide_id: 'foobar' }>
      <SlideLink
        slideId='foobar'
        direction='Next'
        disabled=false
        button=true
        params={ library_id: 'foo', module_id: 'bar' }
      />
    </TrainingSlideHandler>
  )

  beforeEach ->
    TestLink.setState(
      loading: false,
      currentSlide: {content: 'hello'},
      slides: ['a'],
      enabledSlides: [],
      nextSlide: { slug: 'foobar' }
    )

  it 'renders a button', ->
    button = ReactTestUtils.scryRenderedComponentsWithType(TestLink, SlideLink)[0]
    domBtn = ReactDOM.findDOMNode(button)
    expect(domBtn.className).to.eq 'slide-nav btn btn-primary icon icon-rt_arrow'

  it 'renders correct text', ->
    button = ReactTestUtils.scryRenderedComponentsWithType(TestLink, SlideLink)[0]
    domBtn = ReactDOM.findDOMNode(button)
    expect(domBtn.textContent).to.eq 'Next Page'

  it 'renders correct link', ->
    button = ReactTestUtils.scryRenderedComponentsWithType(TestLink, SlideLink)[0]
    domBtn = ReactDOM.findDOMNode(button)
    expected = "/training/foo/bar/foobar"
    # mocha won't render the link with an actual href for some reason…
    expect(domBtn.getAttribute('data-href')).to.eq expected
