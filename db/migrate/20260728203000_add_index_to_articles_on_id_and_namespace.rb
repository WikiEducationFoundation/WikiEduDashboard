# frozen_string_literal: true

class AddIndexToArticlesOnIdAndNamespace < ActiveRecord::Migration[7.0]
  def change
    add_index :articles, %i[id namespace], name: 'index_articles_on_id_and_namespace'
  end
end
