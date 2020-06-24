# frozen_string_literal: true

class FaqTopicsController < ApplicationController
  before_action :require_admin_permissions

  def index
    @faq_topics = FaqTopic.all
  end

  def new
    @topic = FaqTopic.new nil
  end

  def create
    update
  end

  def edit
    @topic = FaqTopic.new(params[:slug])
  end

  def update
    FaqTopic.update(slug: params[:slug], name: params[:name], faqs: faq_param)
    redirect_to '/faq_topics'
  end

  def delete
    FaqTopic.delete(slug: params[:slug])
    redirect_to '/faq_topics'
  end

  private

  def faq_param
    params[:faqs].split(',').map(&:to_i)
  end
end
