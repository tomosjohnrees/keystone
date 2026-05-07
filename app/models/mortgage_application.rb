class MortgageApplication < ApplicationRecord
  MIN_TERM_YEARS = 1
  MAX_TERM_YEARS = 40

  has_one :assessment

  validates :annual_income, :property_value,
            presence: true,
            numericality: { greater_than: 0 }

  validates :monthly_expenses, :deposit_amount,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :term_years,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MIN_TERM_YEARS,
              less_than_or_equal_to: MAX_TERM_YEARS
            }

  validate :deposit_cannot_exceed_property_value

  private

  def deposit_cannot_exceed_property_value
    return if deposit_amount.blank? || property_value.blank?
    return if deposit_amount <= property_value

    errors.add(:deposit_amount, "cannot exceed property value")
  end
end
