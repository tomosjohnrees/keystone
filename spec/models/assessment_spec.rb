require 'rails_helper'

RSpec.describe Assessment, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:mortgage_application) }
  end

  describe 'status enum' do
    it 'defines pending, completed, and failed states' do
      expect(described_class.statuses).to eq(
        'pending'   => 'pending',
        'completed' => 'completed',
        'failed'    => 'failed'
      )
    end

    it 'rejects an unknown status via validation' do
      assessment = build(:assessment, status: 'nope')
      assessment.validate
      expect(assessment.errors[:status]).to be_present
    end
  end

  describe 'after_create_commit enqueue' do
    let(:application) { create(:mortgage_application) }

    it 'enqueues AssessAffordabilityJob when created in pending state' do
      expect {
        application.create_assessment!
      }.to have_enqueued_job(AssessAffordabilityJob)
    end

    it 'does not enqueue when created in a non-pending state' do
      expect {
        application.create_assessment!(status: :completed)
      }.not_to have_enqueued_job(AssessAffordabilityJob)
    end
  end
end
