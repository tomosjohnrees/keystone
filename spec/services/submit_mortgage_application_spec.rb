require 'rails_helper'

RSpec.describe SubmitMortgageApplication do
  subject(:call) { described_class.new(attributes).call }

  let(:attributes) do
    {
      annual_income:    60_000,
      monthly_expenses: 1_500,
      deposit_amount:   50_000,
      property_value:   250_000,
      term_years:       25
    }
  end

  it 'persists a mortgage application' do
    expect { call }.to change(MortgageApplication, :count).by(1)
  end

  it 'creates a pending assessment for the application' do
    application = call
    expect(application.assessment).to be_pending
  end

  it 'enqueues an AssessAffordabilityJob with the assessment' do
    expect { call }.to have_enqueued_job(AssessAffordabilityJob).with(an_instance_of(Assessment))
  end

  it 'returns the persisted application' do
    expect(call).to be_a(MortgageApplication).and be_persisted
  end

  context 'when persistence fails' do
    let(:attributes) { super().merge(annual_income: -1) }

    it 'raises and does not enqueue the job' do
      expect {
        expect { call }.to raise_error(ActiveRecord::RecordInvalid)
      }.not_to have_enqueued_job(AssessAffordabilityJob)
    end

    it 'rolls back the application' do
      expect {
        begin
          call
        rescue ActiveRecord::RecordInvalid
        end
      }.not_to change(MortgageApplication, :count)
    end

    it 'rolls back the assessment' do
      expect {
        begin
          call
        rescue ActiveRecord::RecordInvalid
        end
      }.not_to change(Assessment, :count)
    end
  end
end
