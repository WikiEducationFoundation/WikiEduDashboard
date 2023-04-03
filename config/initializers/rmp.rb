if Rails.env.production?
  Rack::MiniProfiler.config.storage_options = { url: "localhost:11211" }
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemcacheStore
else
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::MemoryStore
end
