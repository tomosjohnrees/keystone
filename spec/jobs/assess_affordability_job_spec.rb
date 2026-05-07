require 'rails_helper'

RSpec.describe AssessAffordabilityJob, type: :job do
  include ActiveJob::TestHelper

  let(:application) { create(:mortgage_application) }
  let(:assessment) { application.create_assessment! }

  describe '#perform' do
    context 'when the calculator succeeds' do
      it 'transitions the assessment to completed and stores the result' do
        described_class.perform_now(assessment)

        assessment.reload
        expect(assessment).to be_completed
        expect(assessment.ltv).to eq(80.0)
        expect(assessment.dti).to eq(30.0)
        expect(assessment.decision).to eq('approved')
        expect(assessment.max_borrowing).to eq(270_000.0)
        expect(assessment.explanation).to start_with('Approved')
        expect(assessment.error_message).to be_nil
      end
    end

    context 'when the calculator raises' do
      before do
        allow(Affordability).to receive(:new).and_raise(StandardError, 'kaboom')
      end

      it 'marks the assessment failed, stores the error, and re-raises' do
        expect {
          described_class.perform_now(assessment)
        }.to raise_error(StandardError, 'kaboom')

        assessment.reload
        expect(assessment).to be_failed
        expect(assessment.error_message).to eq('kaboom')
      end
    end
  end
end
