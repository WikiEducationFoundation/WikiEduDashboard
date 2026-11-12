# frozen_string_literal: true

require 'rails_helper'

describe Institution, type: :model do
  it 'is valid with a name' do
    expect(build(:institution)).to be_valid
  end

  it 'is invalid without a name' do
    expect(build(:institution, name: nil)).not_to be_valid
  end

  it 'is invalid when another institution already has the same name' do
    create(:institution, name: 'Test University')
    expect(build(:institution, name: 'Test University')).not_to be_valid
  end

  it 'refuses to be deleted while it still has courses' do
    institution = create(:institution)
    create(:course, institution: institution)
    expect(institution.destroy).to be false
    expect(Institution.exists?(institution.id)).to be true
  end
end
