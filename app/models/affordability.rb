class Affordability
  include ActiveModel::Validations

  MAX_LTV = BigDecimal("90")
  MAX_DTI = BigDecimal("40")
  INCOME_MULTIPLE = BigDecimal("4.5")

  delegate :annual_income, :monthly_expenses, :property_value,
           :loan_amount, :monthly_income, :disposable_income,
           to: :application

  validate :ltv_within_limit
  validate :dti_within_limit
  validate :loan_within_max_borrowing
  validate :positive_disposable_income

  def initialize(application)
    @application = application
  end

  def ltv
    (loan_amount / property_value) * 100
  end

  def dti
    (monthly_expenses / monthly_income) * 100
  end

  def max_borrowing
    annual_income * INCOME_MULTIPLE
  end

  def decision
    valid? ? "approved" : "declined"
  end

  def explanation
    if valid?
      "Approved: LTV #{ltv.round(2).to_s('F')}%, DTI #{dti.round(2).to_s('F')}%, loan within max borrowing of #{format_money(max_borrowing)}."
    else
      "Declined: #{errors.full_messages.join('; ')}."
    end
  end

  private

  attr_reader :application

  def ltv_within_limit
    return if ltv <= MAX_LTV

    errors.add(:base, "LTV of #{ltv.round(2).to_s('F')}% exceeds the maximum of #{MAX_LTV.to_s('F')}%")
  end

  def dti_within_limit
    return if dti <= MAX_DTI

    errors.add(:base, "DTI of #{dti.round(2).to_s('F')}% exceeds the maximum of #{MAX_DTI.to_s('F')}%")
  end

  def loan_within_max_borrowing
    return if loan_amount <= max_borrowing

    errors.add(:base, "loan amount of #{format_money(loan_amount)} exceeds the maximum borrowing of #{format_money(max_borrowing)}")
  end

  def positive_disposable_income
    return if disposable_income > 0

    errors.add(:base, "monthly expenses exceed monthly income")
  end

  def format_money(value)
    whole, frac = value.round(2).to_s("F").split(".")
    "#{whole}.#{frac.ljust(2, '0')}"
  end
end
