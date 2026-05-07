class AssessmentSerializer
  ATTRIBUTES = %i[
    id
    mortgage_application_id
    status
    ltv
    dti
    decision
    max_borrowing
    explanation
    error_message
    created_at
    updated_at
  ].freeze

  def initialize(assessment)
    @assessment = assessment
  end

  def as_json(*)
    @assessment.as_json(only: ATTRIBUTES)
  end
end
