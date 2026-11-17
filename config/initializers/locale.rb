# frozen_string_literal: true

# The `validates_email_format_of` gem includes `pt-BR.yml`, which adds `:pt-BR`
# to `I18n.available_locales`. Translatewiki and the Dashboard use `:pt-br`
# (and `:pt`). Removing this file from `I18n.load_path` prevents the duplicate
# and incomplete `pt-BR` locale from appearing in the language selector or
# backend locales.
I18n.load_path.reject! { |path| File.basename(path) == 'pt-BR.yml' }
