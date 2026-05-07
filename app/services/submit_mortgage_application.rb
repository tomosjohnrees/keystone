class SubmitMortgageApplication
  def initialize(attributes)
    @attributes = attributes
  end

  def call
    application = MortgageApplication.transaction do
      MortgageApplication.create!(@attributes).tap(&:create_assessment!)
    end

    AssessAffordabilityJob.perform_later(application.assessment)
    application
  end
end
