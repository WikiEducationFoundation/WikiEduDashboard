# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/non_prose_line_filter"

describe NonProseLineFilter do
  def filtered(*lines)
    described_class.new(lines.join("\n")).text.split("\n")
  end

  describe 'bibliography entries' do
    it 'drops reference lines in common citation styles' do
      references = [
        'Perry, J. L., & Wise, L. R. (1990). The Motivational Bases of Public Service. ' \
        'Public Administration Review, 50(3), 367.',
        'Keeley, J.E. (1990). Demographic structure of California black walnut woodlands.',
        'Field, Arthur. The intellectual struggle for Florence. Oxford University Press, 2017.',
        'Brocke, Tiffany; Barr, Justin. 2020. “The History of Wound Healing.” ' \
        'Surgical Clinics of North America, 100(4): 787–806.',
        'De Robertis, Teresa. “Humanistic Script.” The Oxford Handbook of Latin Paleography, ' \
        'November 10, 2020, 521–52.',
        'A. Bansal, M. Vo, Y. Sheikh, "4D Visualization of Dynamic Events." IEEE CVPR, 2020.',
        '"Club History Leicester City". Retrieved November 14, 2020.',
        '“The Photo Essay.” Visual Anthropology Review, 32(2), 115–121.',
        'https://doi.org/10.1093/obo/9780195399301-0175'
      ]
      expect(filtered(*references, 'This source covers his early life.'))
        .to eq(['This source covers his early life.'])
    end

    it 'keeps prose that cites sources in the text' do
      prose = [
        "I will expand the existing discussion using Brown (1968, pp. 203-204 and 209-210).",
        'However, Smith (2019) argues that the policy failed.',
        'Today, Facebook, Instagram and TikTok have billions of users as of 2024.',
        '"Critics argue" is a phrase that needs a source, as noted in 2021.'
      ]
      expect(filtered(*prose)).to eq(prose)
    end
  end

  describe 'preload template instructions' do
    it 'drops instruction lines left from the exercise templates' do
      expect(filtered('Which article are you evaluating?',
                      'Whose work are you reviewing?',
                      '(Provide a link to the article here.)',
                      'The article on Kyushu is short and mostly unsourced.'))
        .to eq(['The article on Kyushu is short and mostly unsourced.'])
    end

    it 'matches template lines regardless of case and spacing' do
      expect(filtered('  Outline of  Proposed Changes ', 'I will add a section.'))
        .to eq(['I will add a section.'])
    end
  end

  describe 'talk page signatures' do
    it 'drops a line that is only a signature' do
      signature = 'LoneStarVinny (talk) 05:49, 3 November 2026 (UTC)'
      expect(filtered('Your sources look good.', signature)).to eq(['Your sources look good.'])
    end

    it 'keeps a comment that ends with a signature' do
      comment = 'Please let me know if you have any suggestions! Logchop (talk) 16:18, ' \
                '22 October 2026 (UTC)'
      expect(filtered(comment)).to eq([comment])
    end
  end

  it 'keeps blank lines and line order' do
    expect(filtered('First.', '', 'Second.')).to eq(['First.', '', 'Second.'])
  end
end
