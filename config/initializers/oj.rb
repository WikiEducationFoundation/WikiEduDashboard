# frozen_string_literal: true

# https://github.com/ohler55/oj/blob/develop/pages/Rails.md
Oj.optimize_rails

# Oj's default :object mode instantiates arbitrary Ruby classes from JSON keys
# such as "^o", so Oj.load on any JSON we did not write ourselves (API responses,
# training content read from wiki pages) would be an insecure-deserialization
# hole. :strict mode returns only JSON-native types (Hash, Array, String, numbers,
# booleans, nil). optimize_rails does not change this default.
Oj.default_options = { mode: :strict }
