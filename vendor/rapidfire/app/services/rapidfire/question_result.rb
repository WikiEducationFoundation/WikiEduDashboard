module Rapidfire
  class QuestionResult < Rapidfire::BaseService
    include ActiveModel::Serialization

    attr_accessor :question, :results

    def active_model_serializer
      Rapidfire::QuestionResultSerializer
    end
  end
end
