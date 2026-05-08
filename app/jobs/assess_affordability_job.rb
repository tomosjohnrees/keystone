class AssessAffordabilityJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 3 do |job, error|
    assessment = job.arguments.first
    assessment.with_lock do
      next unless assessment.pending?

      assessment.update!(status: :failed, error_message: error.message)
    end
  end

  def perform(assessment)
    assessment.with_lock do
      next unless assessment.pending?

      affordability = Affordability.new(assessment.mortgage_application)

      assessment.update!(
        status: :completed,
        ltv: affordability.ltv,
        dti: affordability.dti,
        decision: affordability.decision,
        max_borrowing: affordability.max_borrowing,
        explanation: affordability.explanation
      )
    end
  end
end
