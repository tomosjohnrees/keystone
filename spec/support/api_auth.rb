module ApiAuthHelpers
  def api_auth_headers(token = Rails.configuration.x.keystone.api_token)
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include ApiAuthHelpers, type: :request
end
