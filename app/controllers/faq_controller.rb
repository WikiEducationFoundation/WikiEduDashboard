# frozen_string_literal: true

class FaqController < ApplicationController
  def index
    @query = params[:search]
    @faqs = if @query
              pp 'wat'
              Faq.where('lower(title) like ?', "%#{@query}%")
                 .or(Faq.where('lower(content) like ?', "%#{@query}%"))
            else
              Faq.all
            end
  end

  def show
    @faq = Faq.find(params[:id])
  end

  def new
    @faq = Faq.new
  end

  def create
    @faq = Faq.create!(update_params)
    redirect_to faq_path(@faq)
  end

  def edit
    @faq = Faq.find(params[:id])
  end

  def update
    @faq = Faq.find(params[:id])
    @faq.update!(update_params)
    redirect_to faq_path(@faq)
  end

  def destroy
    @faq = Faq.find(params[:id])
    @faq.destroy!
    redirect_to '/faq'
  end

  private

  def update_params
    params.require(:faq).permit(:title, :content)
  end
end
