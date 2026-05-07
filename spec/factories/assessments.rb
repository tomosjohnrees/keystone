FactoryBot.define do
  factory :assessment do
    mortgage_application
    status { "pending" }

    trait :completed do
      status         { "completed" }
      ltv            { 80.0 }
      dti            { 30.0 }
      decision       { "approved" }
      max_borrowing  { 270_000.0 }
      explanation    { "Approved: LTV 80.0%, DTI 30.0%, loan within max borrowing of 270000.00." }
    end

    trait :failed do
      status         { "failed" }
      error_message  { "boom" }
    end
  end
end
