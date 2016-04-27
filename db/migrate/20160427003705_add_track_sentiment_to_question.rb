class AddTrackSentimentToQuestion < ActiveRecord::Migration
  def change
    add_column :rapidfire_questions, :track_sentiment, :boolean, default: false
  end
end
