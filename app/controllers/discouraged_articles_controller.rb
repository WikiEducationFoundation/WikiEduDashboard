# frozen_string_literal: true

class DiscouragedArticlesController < ApplicationController
  def category_member?
    category_member = WikipediaCategoryMember.find_by(category_member: params[:article_title])
    render json: { is_category_member: category_member.present? }
  end
end
