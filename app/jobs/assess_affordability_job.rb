class AssessAffordabilityJob < ApplicationJob
  queue_as :default

  def perform(assessment)
    result = AffordabilityCalculator.new(assessment.mortgage_application).call

    assessment.update!(
      status: :completed,
      ltv: result.ltv,
      dti: result.dti,
      decision: result.decision,
      max_borrowing: result.max_borrowing,
      explanation: result.explanation
    )
  rescue StandardError => e
    assessment.update!(status: :failed, error_message: e.message)
    raise
  end
end
