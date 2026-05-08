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

      it 'retries up to the limit, then marks the assessment failed and stores the error' do
        perform_enqueued_jobs do
          described_class.perform_later(assessment)
        end

        assessment.reload
        expect(assessment).to be_failed
        expect(assessment.error_message).to eq('kaboom')
      end

      it 'does not overwrite an assessment that is no longer pending when retries are exhausted' do
        completed = create(:assessment, :completed)
        original_updated_at = completed.updated_at

        perform_enqueued_jobs do
          described_class.perform_later(completed)
        end

        completed.reload
        expect(completed).to be_completed
        expect(completed.updated_at).to eq(original_updated_at)
      end
    end

    context 'when the assessment is not pending' do
      it 'is a no-op for a completed assessment' do
        completed = create(:assessment, :completed)
        original_updated_at = completed.updated_at

        described_class.perform_now(completed)

        completed.reload
        expect(completed).to be_completed
        expect(completed.updated_at).to eq(original_updated_at)
      end

      it 'is a no-op for a failed assessment' do
        failed = create(:assessment, :failed)
        original_updated_at = failed.updated_at

        described_class.perform_now(failed)

        failed.reload
        expect(failed).to be_failed
        expect(failed.updated_at).to eq(original_updated_at)
      end
    end
  end
end
