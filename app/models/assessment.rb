class Assessment < ApplicationRecord
  STATUSES = { pending: "pending", completed: "completed", failed: "failed" }.freeze

  belongs_to :mortgage_application

  enum :status, STATUSES, validate: true
end
