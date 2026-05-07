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
end
