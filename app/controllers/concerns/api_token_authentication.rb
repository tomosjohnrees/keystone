require "digest"

module ApiTokenAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_token!
  end

  private

  def authenticate_api_token!
    return if valid_api_token?

    response.set_header("WWW-Authenticate", "Bearer")
    render json: { error: "unauthorized" }, status: :unauthorized
  end

  def valid_api_token?
    expected_token = Rails.configuration.x.keystone.api_token
    provided_token = bearer_token

    return false if expected_token.blank? || provided_token.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(provided_token),
      Digest::SHA256.hexdigest(expected_token)
    )
  end

  def bearer_token
    scheme, token = request.authorization.to_s.split(" ", 2)
    return unless scheme&.casecmp("Bearer")&.zero?

    token
  end
end
