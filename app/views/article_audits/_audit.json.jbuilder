# frozen_string_literal: true

json.call(audit, :id, :mw_rev_id, :article_title, :namespace, :url, :status, :error,
          :created_at, :started_at, :completed_at)
json.wiki audit.wiki.domain
json.revision_url audit.revision_url
json.requester audit.requester&.username
