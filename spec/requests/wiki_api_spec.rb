require 'rails_helper'
require 'media_wiki'

RSpec.describe "Wiki API" do

  before(:each) do
    @mw = MediaWiki::Gateway.new('http://en.wikipedia.org/w/api.php')
    @mw.login(Figaro.env.wikipedia_username, Figaro.env.wikipedia_password)
  end

  # it "should return students in a course" do
  #   response = @mw.send_request({
  #     'action' => 'liststudents',
  #     'courseids' => '366',
  #     'format' => 'json'
  #   })
  #   expect(response).not_to be_nil
  # end

  # it "should return earliest date an article was edited by a certain user" do
  #   response = @mw.send_request({
  #     'action' => 'query',
  #     'prop' => 'revisions',
  #     'titles' => URI.escape('History of biology'),
  #     'rvlimit' => 5,
  #     'rvdir' => 'newer',
  #     'rvstart' => '2007-05-01T00:00:00Z',
  #     'rvprop' => 'timestamp|user|comment',
  #     'rvuser' => 'Ragesoss',
  #     'rawcontinue' => true # This reflects a problem in the media_wiki gem 
  #   })
  #   expect(response).not_to be_nil
  # end

end
