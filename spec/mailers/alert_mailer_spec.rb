require 'rails_helper'

describe AlertMailer do
  let(:user) { create(:user, email: 'user@wikiedu.org') }
  let(:article) { create(:article, title: 'Almost_deleted') }
  let(:course) { create(:course) }

  describe '.alert' do
    let(:mail) { described_class.alert(alert, user) }

    context 'for an ArticlesForDeletionAlert' do
      let(:alert) do
        create(:alert, type: 'ArticlesForDeletionAlert', article_id: article.id)
        Alert.last
      end

      it 'delivers an email with to the recipient' do
        expect(Features).to receive(:email?).and_return(true)
        expect(mail.subject).to match(article.title)
        expect(mail.to).to eq([user.email])
      end
    end

    context 'for a NoEnrolledStudentsAlert' do
      let(:alert) do
        create(:alert, type: 'NoEnrolledStudentsAlert', course_id: course.id)
        Alert.last
      end

      it 'delivers an email with to the recipient' do
        expect(Features).to receive(:email?).and_return(true)
        expect(mail.subject).to include(course.slug)
        expect(mail.to).to eq([user.email])
      end
    end
  end
end
