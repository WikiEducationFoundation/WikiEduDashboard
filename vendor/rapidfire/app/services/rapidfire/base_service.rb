module Rapidfire
  class BaseService
    if Rails::VERSION::MAJOR == 4
      include ActiveModel::Model
    else
      extend  ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations

      def persisted; false end

      def initialize(params={})
        params.each do |attr, value|
          self.public_send("#{attr}=", value)
        end if params

        super()
      end
    end
  end
end
