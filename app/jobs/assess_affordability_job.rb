class AssessAffordabilityJob < ApplicationJob
  queue_as :default

  def perform(assessment)
    affordability = Affordability.new(assessment.mortgage_application)

    assessment.update!(
      status: :completed,
      ltv: affordability.ltv,
      dti: affordability.dti,
      decision: affordability.decision,
      max_borrowing: affordability.max_borrowing,
      explanation: affordability.explanation
    )
  rescue StandardError => e
    assessment.update!(status: :failed, error_message: e.message)
    raise
  end
end
