require 'rails_helper'

RSpec.describe MortgageApplication, type: :model do
  let(:application) do
    build(
      :mortgage_application,
      annual_income:    60_000,
      monthly_expenses: 1_500,
      deposit_amount:   50_000,
      property_value:   250_000
    )
  end

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

  describe '#loan_amount' do
    it 'returns property_value minus deposit_amount' do
      expect(application.loan_amount).to eq(200_000)
    end
  end

  describe '#monthly_income' do
    it 'returns annual_income divided by twelve' do
      expect(application.monthly_income).to eq(5_000)
    end
  end

  describe '#disposable_income' do
    it 'returns monthly_income minus monthly_expenses' do
      expect(application.disposable_income).to eq(3_500)
    end
  end
end
