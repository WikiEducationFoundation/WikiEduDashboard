require 'rails_helper'

describe CourseHelper, type: :helper do
  describe '#date_highlight_class' do
    it 'returns "ending-soon" for courses ending soon' do
      course = build(:course, start: 1.month.ago, end: 5.days.from_now)
      expect(date_highlight_class(course)).to eq('ending-soon')
    end
    it 'returns "just-started" for courses that started recently' do
      course = build(:course, start: 5.days.ago, end: 1.month.from_now)
      expect(date_highlight_class(course)).to eq('just-started')
    end
    it 'returns empty string for other courses' do
      course = build(:course, start: 1.month.ago, end: 1.month.from_now)
      expect(date_highlight_class(course)).to eq('')
    end
  end
end
