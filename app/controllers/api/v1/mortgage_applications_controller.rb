module Api
  module V1
    class MortgageApplicationsController < BaseController
      def create
        application = MortgageApplication.create!(application_params)
        render json: MortgageApplicationSerializer.new(application), status: :created
      end

      private

      def application_params
        params.require(:mortgage_application).permit(
          :annual_income, :monthly_expenses, :deposit_amount,
          :property_value, :term_years
        )
      end
    end
  end
end
