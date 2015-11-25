require '../../testHelper'
ActivityTableRow = require '../../../app/assets/javascripts/components/activity/activity_table_row'
ActivityTable = require '../../../app/assets/javascripts/components/activity/activity_table'
CustomUtils = require '../../customUtils'
click = CustomUtils.click

describe 'ActivtyTableRow', ->
  TestRow = ReactTestUtils.renderIntoDocument(
    <ActivityTable
      loading=false
      activity={[{ key: '1', revision_score: 0, title: 'Foobar', courses: [{id: 1}, {id: 2}]}]}
      headers={[{key: '1' }]}
      noActivityMessage='Hello world'>
      <ActivityTableRow
        key={Math.random() * 20}
        rowId=675818536
        title='Selfie'
        articleUrl='https://en.wikipedia.org/wiki/Selfie'
        author='Wavelength'
        talkPageLink='https://en.wikipedia.org/wiki/User_talk:Wavelength'
        diffUrl='https://en.wikipedia.org/w/index.php?title=Selfie&diff=675818536&oldid=675437996'
        revisionDateTime='2015/08/012 9:43 pm'
        revisionScore=61
      />
    </ActivityTable>
  )

  it 'renders a table row with activity-table-row class and closed class', ->
    rows = ReactTestUtils.scryRenderedDOMComponentsWithTag(TestRow, 'tr')
    # rows[0] is header row
    expect(rows[1].className).to.eq 'activity-table-row closed'

  it 'changes class open to class closed when state is_open', ->
    row = ReactTestUtils.scryRenderedDOMComponentsWithClass(TestRow, 'activity-table-row')[0]
    expect(row.className).to.eq('activity-table-row closed')
    click(row).then (row) -> expect(row.className).to.eq('activity-table-row open')
