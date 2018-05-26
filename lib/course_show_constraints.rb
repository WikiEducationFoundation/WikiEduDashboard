
require './lib/course_show_endpoints'
module CourseShowConstraints
  CourseShowEndPoints::ENDPOINTS.each do |endpoint|
    constraint = Class.new do
      def matches?(request)
        request.params[:endpoint] == self.class.to_s.underscore.split('/')[1]
      end
    end
    self.const_set(endpoint.camelize, constraint)
  end
end
