#!/usr/bin/env ruby
# frozen_string_literal: true

# The simplest possible verifier, as a baseline and a working example of the
# interface ClaimLibrary::VerifierComparison expects: one claim as JSON on
# standard input, one JSON object with a verdict on standard output.
#
#   VERIFIER=lib/claim_library/verifiers/always_full_support.rb rake claim_library:benchmark

require 'json'

JSON.parse($stdin.read)
puts JSON.generate('verdict' => 'full_support', 'reason' => 'baseline: accepts every claim')
