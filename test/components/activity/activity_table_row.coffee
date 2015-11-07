require '../../testHelper'
ActivityTableRow = require '../../../app/assets/javascripts/components/activity/activity_table_row'

describe 'ActivtyTableRow', ->
  TestRow = ReactTestUtils.renderIntoDocument(
    <table>
    <ActivityTableRow
      rowId=675818536
      title='Selfie'
      articleUrl='https://en.wikipedia.org/wiki/Selfie'
      author='Wavelength'
      talkPageLink='https://en.wikipedia.org/wiki/User_talk:Wavelength'
      diffUrl='https://en.wikipedia.org/w/index.php?title=Selfie&diff=675818536&oldid=675437996'
      revisionDateTime='2015/08/012 9:43 pm'
      revisionScore=61
    />
    </table>
  )
  it 'renders a table row with activity-table-row class and closed class', ->
    renderedRow = ReactTestUtils.findRenderedDOMComponentWithTag(TestRow, 'tr')
    renderedRow.getDOMNode().className.should.equal 'activity-table-row closed'
  it 'changes class open to class closed when state is_open', ->
    renderedRow = ReactTestUtils.findRenderedDOMComponentWithClass(TestRow, 'activity-table-row')
    Simulate.click(renderedRow)
    # FIXME: make the row switch from closed to open
    # renderedRow.getDOMNode().className.should.equal 'activity-table-row open'
