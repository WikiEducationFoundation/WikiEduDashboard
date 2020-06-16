# frozen_string_literal: true

class FaqController < ApplicationController
  def index
    @faqs = Faq.all
  end

  def show
    @faq = Faq.find(params[:id])
  end

  def create; end

  def edit
    @faq = Faq.find(params[:id])
  end

  def update
    @faq = Faq.find(params[:id])
    @faq.update!(update_params)
    redirect_to faq_path(@faq)
  end

  def destroy; end

  private

  def update_params
    params.require(:faq).permit(:title, :content)
  end
end
