class MortgageApplicationSerializer
  ATTRIBUTES = %i[
    id
    annual_income
    monthly_expenses
    deposit_amount
    property_value
    term_years
    created_at
    updated_at
  ].freeze

  def initialize(application)
    @application = application
  end

  def as_json(*)
    @application.as_json(only: ATTRIBUTES)
  end
end
