FactoryBot.define do
  factory :mortgage_application do
    annual_income     { 60_000.00 }
    monthly_expenses  { 1_500.00 }
    deposit_amount    { 50_000.00 }
    property_value    { 250_000.00 }
    term_years        { 25 }
  end
end
