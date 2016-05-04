require 'rails_helper'

describe 'greetings:welcome_students' do
  include_context 'rake'

  it 'calls StudentGreeter' do
    expect(StudentGreeter).to receive(:greet_all_ungreeted_students)
    subject.invoke
  end
end
