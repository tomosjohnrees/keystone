require 'rails_helper'

RSpec.describe MortgageApplication, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:annual_income) }
    it { is_expected.to validate_presence_of(:monthly_expenses) }
    it { is_expected.to validate_presence_of(:deposit_amount) }
    it { is_expected.to validate_presence_of(:property_value) }
    it { is_expected.to validate_presence_of(:term_years) }

    it { is_expected.to validate_numericality_of(:annual_income).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:property_value).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:monthly_expenses).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:deposit_amount).is_greater_than_or_equal_to(0) }

    it do
      is_expected.to validate_numericality_of(:term_years)
        .only_integer
        .is_greater_than_or_equal_to(described_class::MIN_TERM_YEARS)
        .is_less_than_or_equal_to(described_class::MAX_TERM_YEARS)
    end

    describe 'deposit cannot exceed property value' do
      subject(:application) do
        build(:mortgage_application, deposit_amount: deposit_amount, property_value: property_value)
      end

      context 'when the deposit is below the property value' do
        let(:deposit_amount) { 50_000 }
        let(:property_value) { 250_000 }

        it { is_expected.to be_valid }
      end

      context 'when the deposit equals the property value' do
        let(:deposit_amount) { 250_000 }
        let(:property_value) { 250_000 }

        it { is_expected.to be_valid }
      end

      context 'when the deposit exceeds the property value' do
        let(:deposit_amount) { 250_001 }
        let(:property_value) { 250_000 }

        it { is_expected.to be_invalid }

        it 'adds a "cannot exceed property value" error on deposit_amount' do
          application.validate
          expect(application.errors[:deposit_amount]).to include('cannot exceed property value')
        end
      end
    end
  end
end
