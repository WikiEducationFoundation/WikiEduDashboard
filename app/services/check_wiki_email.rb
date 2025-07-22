# frozen_string_literal: true

class CheckWikiEmail
  def initialize(user:, wiki:)
    @user = user
    @wiki = wiki
  end

  def emailable?
    emailable_query = { list: 'users',
                        usprop: 'emailable',
                        ususers: @user.username }
    response = WikiApi.new(@wiki).query emailable_query
    response.data['users'].first.key? 'emailable'
  end
end
