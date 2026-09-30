# frozen_string_literal: true

require 'rails_helper'

# config/initializers/oj.rb switches Oj from its default :object mode, which
# instantiates arbitrary Ruby classes from "^o" keys, to :strict mode. Several
# Oj.load call sites parse JSON the Dashboard did not write (API responses,
# training content read from wiki pages), so this pins the security property.
describe 'Oj initializer' do
  it 'sets strict mode as the default' do
    expect(Oj.default_options[:mode]).to eq(:strict)
  end

  it 'returns a plain Hash for a payload with an object-instantiation key' do
    parsed = Oj.load('{"^o":"Object","x":1}')
    expect(parsed).to eq('^o' => 'Object', 'x' => 1)
  end

  it 'keeps strings that begin with a colon as strings' do
    expect(Oj.load('[":foo"]')).to eq([':foo'])
  end
end
