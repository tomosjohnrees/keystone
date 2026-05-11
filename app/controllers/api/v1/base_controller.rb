module Api
  module V1
    class BaseController < ActionController::API
      include ApiTokenAuthentication

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def render_not_found
        render json: { error: "not_found" }, status: :not_found
      end

      def render_unprocessable(exception)
        render json: { errors: exception.record.errors.as_json }, status: :unprocessable_content
      end

      def render_bad_request(exception)
        render json: { error: "bad_request", message: exception.message }, status: :bad_request
      end
    end
  end
end
