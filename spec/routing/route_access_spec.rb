# frozen_string_literal: true

require 'rails_helper'

# Every routed controller action, and every mounted app, needs a reviewed
# access level in config/route_access.yml (see the levels there).
describe 'Route access manifest', type: :request do
  manifest = YAML.load_file(Rails.root.join('config/route_access.yml'))
  levels = %w[public token signed_in self participant editor organizer admin super_admin
              development none]
  # Levels a logged-out request must not get through.
  protected_levels = %w[signed_in self participant editor organizer admin super_admin]

  # [key, verb, path] for each route; engine routes get their mount path.
  collect = lambda do |route_set, prefix = ''|
    route_set.routes.flat_map do |route|
      app = route.app.respond_to?(:app) ? route.app.app : route.app
      path = prefix + route.path.spec.to_s
      if route.defaults[:controller]
        [["#{route.defaults[:controller]}##{route.defaults[:action]}", route.verb, path]]
      elsif app.respond_to?(:routes) && app.routes.is_a?(ActionDispatch::Routing::RouteSet)
        collect.call(app.routes, path)
      elsif app.is_a?(ActionDispatch::Routing::Redirect)
        []
      else
        [[path, route.verb, path]]
      end
    end
  end
  routes = collect.call(Rails.application.routes)
  route_keys = routes.map(&:first).uniq

  it 'has an access level for every route' do
    missing = route_keys - manifest.keys
    expect(missing).to be_empty, "Add these to config/route_access.yml: #{missing.join(', ')}"
  end

  # Development-only routes (such as rails/info) don't exist in the test
  # environment.
  it 'lists no routes that no longer exist' do
    development_only = manifest.select { |_key, level| level == 'development' }.keys
    stale = manifest.keys - route_keys - development_only
    expect(stale).to be_empty, "Remove these from config/route_access.yml: #{stale.join(', ')}"
  end

  it 'uses only the defined levels' do
    unknown = manifest.reject { |_key, level| levels.include?(level) }
    expect(unknown).to be_empty
  end

  # A route that claims to need a signed-in user must not answer a logged-out
  # request with a success. Path params get placeholder values, so actions that
  # look a record up first answer 404, which passes; this catches actions that
  # work without a session at all.
  it 'refuses logged-out requests to routes that need a signed-in user' do
    # Records the placeholder path values find, so that actions which look one
    # up first get as far as their access check.
    user = create(:user, id: 1, username: '1')
    course = create(:course, id: 1, slug: '1/1', school: '1', title: '1', term: '',
                             start: 1.month.ago, end: 1.month.from_now)
    create(:campaign, id: 1, slug: '1', title: '1').courses << course
    article = create(:article, id: 1, title: '1')
    create(:courses_user, id: 1, course:, user:)
    create(:assignment, id: 1, course:, user:, article:, article_title: '1')
    create(:block, id: 1, week: create(:week, id: 1, course:))
    create(:alert, id: 1, course:, user:)
    create(:survey, id: 1)
    question_group = Rapidfire::QuestionGroup.create!(id: 1, name: '1')
    create(:q_long, id: 1, question_group_id: question_group.id)
    succeeded = []
    routes.each do |key, verb, path|
      next unless protected_levels.include?(manifest[key])
      url = path.gsub(/\(\.:format\)|\(\.:\w+\)/, '').gsub(/\*\w+/, '1/1').gsub(/:\w+/, '1')
      url = url.gsub(/[()]/, '')
      verb.split('|').presence&.each do |method|
        status = begin
          process(method.downcase.to_sym, url)
          response.status
        rescue StandardError
          500
        end
        # A path shared by several routes (such as the signed-in and logged-out
        # roots) may reach a different action, which has its own entry.
        reached = controller && "#{controller.controller_path}##{controller.action_name}"
        next unless reached == key
        succeeded << "#{method} #{url} (#{key}): #{status}" if status.between?(200, 299)
      end
    end
    expect(succeeded).to be_empty, "Answered logged out:\n#{succeeded.join("\n")}"
  end
end
