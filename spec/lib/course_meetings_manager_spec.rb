require 'rails_helper'

describe CourseMeetingsManager do
  # starts with a comma to mimic real data. will fix data later
  let(:day_ex) { ",20151013,20151201,20151203,20151208,20151210,20151215,20151217,20151222,
                  20151224,20151229,20151231,20160105,20160107" }
  let!(:course) do
    create(:course,
           timeline_start: Date.new(2015, 8, 25),
           timeline_end: Date.new(2016, 5, 01),
           day_exceptions: day_ex,
           weekdays: '0010100'
          )
  end

  let(:expected) do
    ["(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "()", "()", "()", "()", "()", "()", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)", "(Tue, Thu)"]
  end

  describe '#week_meetings' do
    subject { described_class.new(course).week_meetings }
    it 'returns an array of day meetings for each week, factoring in blackout dates' do
      expect(subject).to eq(expected)
    end
  end

  describe '#day_meetings' do
    subject { described_class.new(course).day_meetings }
    it 'returns an array of symbols reprensenting the course meeting days' do
      expect(subject).to eq([:tuesday, :thursday])
    end
  end

  describe '#timeline_week_count' do
    subject { described_class.new(course).timeline_week_count }
    it 'returns an integer representing the weeks in the timeline, irrespective of blackouts' do
      expect(subject).to eq(36)
    end
  end

  describe '#all_potential_meetings' do
    let(:expected) do
      [ Date.new(2015, 8, 25),
        Date.new(2015, 8, 27),
        Date.new(2015, 9, 01) ]
    end
    subject { described_class.new(course).all_potential_meetings }
    it 'returns an array of all days the course would have met, irrespective of blackouts' do
      expect(subject.first(3)).to eq(expected)
    end
  end

  describe '#open_weeks' do
    subject { described_class.new(course).open_weeks }
    before { allow_any_instance_of(Course).to receive(:weeks).and_return(14) }
    it 'returns an int representing the weeks the timeline can accomodate' do
      expect(subject).to eq(22)
    end
  end

end
