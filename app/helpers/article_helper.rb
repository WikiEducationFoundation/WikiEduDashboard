#= Helpers for article views
module ArticleHelper
  def rating_priority(rating)
    case rating
    when 'fa', 'fl'
      0
    when 'a'
      1
    when 'ga'
      2
    when 'b'
      3
    when 'c'
      4
    when 'start'
      5
    when 'stub'
      6
    when 'list'
      7
    when nil
      8
    end
  end
end
