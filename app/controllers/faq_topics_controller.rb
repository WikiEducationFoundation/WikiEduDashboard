# frozen_string_literal: true

class FaqTopicsController < ApplicationController
  def index
    @faq_topics = FaqTopic.all
  end

  def new
    @topic = FaqTopic.new nil
  end

  def create
    FaqTopic.update(slug: params[:slug], name: params[:name], faqs: faq_param)
  end

  private

  def faq_param
    params[:faqs].split(',').map(&:to_i)
  end
end
