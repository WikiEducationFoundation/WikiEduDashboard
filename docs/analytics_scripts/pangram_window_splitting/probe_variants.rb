# Ablation probe for one flagged text: scores formatting-only variants of the exact text
# production sent, with Pangram 4 or an Originality 5 model, one call per variant.
#   bin/rails runner probe_variants.rb <dir> pangram
#   bin/rails runner probe_variants.rb <dir> model-5.0|model-5.0-max
# <dir> holds sent.txt (the plain text production sent: a two-line header, the body, a
# talk-page signature). Responses are saved as <dir>/<detector>_<variant>.json; existing
# files are skipped, so delete one to re-score it. ONLY=A_sent,D_sent_fix_amp limits variants.
require 'json'
require_dependency "#{Rails.root}/lib/pangram_api"
require_dependency "#{Rails.root}/lib/originality_api"

dir, detector = ARGV
sent = File.read(File.join(dir, 'sent.txt'))
lines = sent.split("\n")
header = "#{lines[0..1].join("\n")}\n\n"
sig = lines.last
body = sent.delete_prefix(header).sub(/\n+#{Regexp.escape(sig)}\z/, '')
raise 'header/body/signature split failed' unless "#{header}#{body}\n\n#{sig}" == sent

amp = ->(text) { text.gsub('&amp;', '&') }
# The signature as the user's browser rendered it in their re-run.
sig_local = "#{sig.split(' (talk)').first} (talk) 11:15 am, Yesterday (UTC−5)"

variants = {
  'A_sent' => sent,
  'B_body_amp' => body,
  'C_user_full' => amp.call("#{header}#{body}\n\n#{sig_local}"),
  'D_sent_fix_amp' => amp.call(sent),
  'E_sent_no_sig' => "#{header}#{body}",
  'F_sent_no_header' => "#{body}\n\n#{sig}",
  'G_sent_local_sig' => "#{header}#{body}\n\n#{sig_local}",
  'H_body_fixed_amp' => amp.call(body)
}
only = ENV['ONLY']&.split(',')
variants.select! { |name, _| only.include?(name) } if only

score = if detector == 'pangram'
          api = PangramApi.v4
          ->(text) { api.inference(text) }
        else
          conn = Faraday.new(url: OriginalityApi::API_URL, headers: OriginalityApi.api_headers,
                             request: { open_timeout: 5, timeout: 180 })
          lambda do |text|
            body = { title: 'probe', content: text, aiModelVersion: detector, check_ai: true,
                     check_plagiarism: false, check_facts: false, check_readability: false,
                     check_grammar: false, storeScan: true }
            JSON.parse(conn.post('') { |req| req.body = body.to_json }.body)
          end
        end

variants.each do |name, text|
  path = File.join(dir, "#{detector}_#{name}.json")
  next puts("#{name}: cached") if File.exist?(path)

  File.write(path, JSON.pretty_generate({ 'input' => text, 'response' => score.call(text) }))
  puts "#{name}: saved"
end
