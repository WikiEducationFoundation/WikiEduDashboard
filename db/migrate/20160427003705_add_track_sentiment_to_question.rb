class AddTrackSentimentToQuestion < ActiveRecord::Migration[4.2]
  def change
    add_column :rapidfire_questions, :track_sentiment, :boolean, default: false
  end
end
