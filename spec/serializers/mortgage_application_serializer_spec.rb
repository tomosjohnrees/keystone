require 'rails_helper'

RSpec.describe MortgageApplicationSerializer do
  let(:application) { create(:mortgage_application) }

  subject(:payload) { described_class.new(application).as_json }

  it 'exposes exactly the public attributes' do
    expect(payload.keys).to match_array(%w[
      id
      annual_income
      monthly_expenses
      deposit_amount
      property_value
      term_years
      created_at
      updated_at
    ])
  end

  it 'returns the underlying attribute values' do
    expect(payload).to include(
      'id' => application.id,
      'annual_income' => application.annual_income.to_s,
      'monthly_expenses' => application.monthly_expenses.to_s,
      'deposit_amount' => application.deposit_amount.to_s,
      'property_value' => application.property_value.to_s,
      'term_years' => application.term_years
    )
  end
end
