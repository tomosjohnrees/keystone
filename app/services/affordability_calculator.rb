class AffordabilityCalculator
  include ActiveModel::Validations

  Result = Data.define(:ltv, :dti, :decision, :max_borrowing, :explanation)

  MAX_LTV = 90.0
  MAX_DTI = 40.0
  INCOME_MULTIPLE = 4.5

  validate :ltv_within_limit
  validate :dti_within_limit
  validate :loan_within_max_borrowing
  validate :positive_disposable_income

  def initialize(application)
    @application = application
  end

  def call
    Result.new(ltv:, dti:, decision:, max_borrowing:, explanation:)
  end

  private

  attr_reader :application

  def ltv_within_limit
    return if ltv <= MAX_LTV

    errors.add(:base, "LTV of #{ltv}% exceeds the maximum of #{MAX_LTV}%")
  end

  def dti_within_limit
    return if dti <= MAX_DTI

    errors.add(:base, "DTI of #{dti}% exceeds the maximum of #{MAX_DTI}%")
  end

  def loan_within_max_borrowing
    return if loan_amount <= max_borrowing

    errors.add(:base, "loan amount of #{format_money(loan_amount)} exceeds the maximum borrowing of #{format_money(max_borrowing)}")
  end

  def positive_disposable_income
    return if disposable_income > 0

    errors.add(:base, "monthly expenses exceed monthly income")
  end

  def decision
    valid? ? "approved" : "declined"
  end

  def ltv
    ((loan_amount / application.property_value) * 100).to_f.round(2)
  end

  def dti
    ((application.monthly_expenses / monthly_income) * 100).to_f.round(2)
  end

  def max_borrowing
    (application.annual_income * INCOME_MULTIPLE).to_f.round(2)
  end

  def loan_amount
    application.property_value - application.deposit_amount
  end

  def monthly_income
    application.annual_income / 12.0
  end

  def disposable_income
    monthly_income - application.monthly_expenses
  end

  def explanation
    if errors.empty?
      "Approved: LTV #{ltv}%, DTI #{dti}%, loan within max borrowing of #{format_money(max_borrowing)}."
    else
      "Declined: #{errors.full_messages.join('; ')}."
    end
  end

  def format_money(value)
    format("%.2f", value)
  end
end
