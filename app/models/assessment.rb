class Assessment < ApplicationRecord
  STATUSES = { pending: "pending", completed: "completed", failed: "failed" }.freeze

  belongs_to :mortgage_application

  enum :status, STATUSES, validate: true

  after_create_commit :enqueue_calculation, if: :pending?

  private

  def enqueue_calculation
    AssessAffordabilityJob.perform_later(self)
  end
end
