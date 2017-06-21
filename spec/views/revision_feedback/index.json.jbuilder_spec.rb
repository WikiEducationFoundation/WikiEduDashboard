require "spec_helper"

describe "revision_feedback/index.json.jbuilder", type: :view do
	it "displays the feedback" do
		feedback = []
		feedback << '[no suggestions available]'
		assign(:feedback, feedback)
		render :template => "revision_feedback/index.json.jbuilder"

		puts rendered
		expect(rendered).to have_key('suggestions')
    expect(rendered['suggestions'].length).to be equal(1)
	end
end