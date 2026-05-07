module Api
  module V1
    class AssessmentsController < BaseController
      def show
        application = MortgageApplication.find(params[:mortgage_application_id])
        assessment = application.assessment
        raise ActiveRecord::RecordNotFound unless assessment

        render json: AssessmentSerializer.new(assessment)
      end
    end
  end
end
