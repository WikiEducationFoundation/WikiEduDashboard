require 'spec_helper'
require 'rake'
load File.expand_path('../../../lib/tasks/change_delimiter_to_srsn.rake', __FILE__)


describe 'rapidfire:change_delimiter_from_comma_to_srsn' do
  before do
    Rake::Task.define_task(:environment)
  end

  it 'converts select,radio and checkbox answer options delimiter from , to \r\n' do
    question_group = FactoryGirl.create(:question_group)
    q_checkbox = FactoryGirl.create(:q_checkbox, question_group: question_group,
                                    answer_options: 'one,two,three')
    q_radio = FactoryGirl.create(:q_radio, question_group: question_group,
                                 answer_options: 'hello,world')
    q_select = FactoryGirl.create(:q_select, question_group: question_group,
                                  answer_options: 'new,old,historic,')

    q_date = FactoryGirl.create(:q_date, question_group: question_group)
    q_long = FactoryGirl.create(:q_long, question_group: question_group)
    q_numeric = FactoryGirl.create(:q_numeric, question_group: question_group)
    q_short = FactoryGirl.create(:q_short, question_group: question_group)

    Rake::Task['rapidfire:change_delimiter_from_comma_to_srsn'].invoke

    expect(q_checkbox.reload.answer_options).to eq "one\r\ntwo\r\nthree"
    expect(q_radio.reload.answer_options).to eq "hello\r\nworld"
    expect(q_select.reload.answer_options).to eq "new\r\nold\r\nhistoric"
  end
end
