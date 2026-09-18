# frozen_string_literal: true

require 'rails_helper'

describe LtiProgressPreload do
  let(:course) { create(:course) }
  let(:zoe) { create(:user, username: 'Zoe') }
  let(:adam) { create(:user, username: 'Adam') }
  let(:week_two) { create(:week, course:, order: 1) }
  let(:week_one) { create(:week, course:, order: 0) }
  let(:training) { create(:training_module, slug: 'tr-a', name: 'Training', kind: 0) }
  let(:exercise) do
    create(:training_module, slug: 'ex-a', name: 'Exercise', kind: 1,
                             settings: { 'sandbox_location' => 'A' })
  end

  subject(:preload) { described_class.new(course:, user_ids: [zoe.id, adam.id]) }

  before do
    # Created out of timeline order, so ordering has to come from week and block order.
    create(:block, week: week_two, order: 0, title: 'Later', training_module_ids: [exercise.id])
    create(:block, week: week_one, order: 1, title: 'Second', training_module_ids: [training.id])
    create(:block, week: week_one, order: 0, title: 'First', training_module_ids: [])
    TrainingModulesUsers.create!(user: zoe, training_module: training, completed_at: 1.day.ago)
    Assignment.create!(course:, user: zoe, wiki: course.home_wiki,
                       role: Assignment::Roles::ASSIGNED_ROLE, article_title: 'Ada_Lovelace')
    Assignment.create!(course:, user: zoe, wiki: course.home_wiki,
                       role: Assignment::Roles::REVIEWING_ROLE, article_title: 'Grace_Hopper')
  end

  it 'lists the blocks in timeline order with their weeks loaded' do
    expect(preload.blocks.map(&:title)).to eq(%w[First Second Later])
    expect(preload.blocks).to all(satisfy { |block| block.association(:week).loaded? })
  end

  it "resolves a block's modules in the block's order" do
    later = preload.blocks.last
    expect(preload.modules_for(later)).to eq([exercise])
    expect(preload.modules_for(preload.blocks.first)).to eq([])
  end

  it 'collects the training-kind modules and leaves exercises out' do
    expect(preload.training_modules).to eq([training])
  end

  it 'keys each user\'s completions by module' do
    expect(preload.completions_for(zoe.id).keys).to eq([training.id])
    expect(preload.completions_for(zoe.id)[training.id].completed_at).to be_present
    expect(preload.completions_for(adam.id)).to eq({})
  end

  it 'groups assignments by user with their associations loaded' do
    zoe_assignments = preload.assignments_for(zoe.id)
    expect(zoe_assignments.map(&:article_title)).to eq(%w[Ada_Lovelace Grace_Hopper])
    expect(zoe_assignments).to all(satisfy { |a| a.association(:wiki).loaded? })
    expect(zoe_assignments).to all(satisfy { |a| a.association(:course).loaded? })
    expect(preload.assignments_for(adam.id)).to eq([])
  end

  it 'reads the whole set in one query per table, however many users' do
    preload.blocks
    counted = 0
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      counted += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name])
    end
    [zoe, adam].each do |user|
      preload.training_modules
      preload.completions_for(user.id)
      preload.assignments_for(user.id)
    end
    ActiveSupport::Notifications.unsubscribe(subscriber)
    # training_modules, training_modules_users, assignments + its four preloads
    expect(counted).to be <= 7
  end
end
