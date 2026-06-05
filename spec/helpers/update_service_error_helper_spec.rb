# frozen_string_literal: true

require 'rails_helper'
require './lib/errors/update_service_error_helper'

RSpec.describe UpdateServiceErrorHelper do
  subject do
    Class.new do
      include UpdateServiceErrorHelper
    end.new
  end

  describe '#update_error_stats' do
    it 'increments error_count by 1 when no argument is given' do
      expect { subject.update_error_stats }.to change(subject, :error_count).by(1)
    end

    it 'increments error_count by the given number of errors' do
      expect { subject.update_error_stats(5) }.to change(subject, :error_count).by(5)
    end

    it 'increments error_count multiple times with different values' do
      subject.update_error_stats(3)
      expect(subject.error_count).to eq(3)

      subject.update_error_stats(2)
      expect(subject.error_count).to eq(5)
    end
  end

  describe '#record_too_many_requests' do
    it 'starts at 0' do
      expect(subject.too_many_requests_count).to eq(0)
    end

    it 'increments too_many_requests_count by 1 when no argument is given' do
      expect { subject.record_too_many_requests }
        .to change(subject, :too_many_requests_count).by(1)
    end

    it 'increments too_many_requests_count by the given count' do
      expect { subject.record_too_many_requests(4) }
        .to change(subject, :too_many_requests_count).by(4)
    end
  end
end
