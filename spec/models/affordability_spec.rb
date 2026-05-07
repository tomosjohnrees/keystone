require 'rails_helper'

RSpec.describe Affordability do
  subject(:result) { described_class.new(application) }

  def build_application(**overrides)
    attrs = {
      annual_income:    60_000,
      monthly_expenses: 1_500,
      deposit_amount:   50_000,
      property_value:   250_000,
      term_years:       25
    }.merge(overrides)
    build_stubbed(:mortgage_application, **attrs)
  end

  let(:application) { build_application }

  describe '#ltv' do
    it 'is the loan as a percentage of property value' do
      expect(result.ltv).to eq(80.0)
    end

    context 'when deposit equals property value' do
      let(:application) do
        build_application(deposit_amount: 250_000, property_value: 250_000)
      end

      it 'is zero' do
        expect(result.ltv).to eq(0.0)
      end
    end
  end

  describe '#dti' do
    it 'is monthly expenses as a percentage of monthly income' do
      expect(result.dti).to eq(30.0)
    end
  end

  describe '#max_borrowing' do
    it 'is the annual income multiplied by the income multiple' do
      expect(result.max_borrowing).to eq(270_000.0)
    end
  end

  describe '#decision' do
    context 'when the application is within all thresholds' do
      it 'is approved' do
        expect(result.decision).to eq('approved')
      end
    end

    context 'when LTV exceeds the maximum' do
      let(:application) do
        build_application(annual_income: 100_000, deposit_amount: 10_000)
      end

      it 'is declined' do
        expect(result.decision).to eq('declined')
      end
    end

    context 'when DTI exceeds the maximum' do
      let(:application) { build_application(monthly_expenses: 2_500) }

      it 'is declined' do
        expect(result.decision).to eq('declined')
      end
    end

    context 'when the loan exceeds max borrowing' do
      let(:application) do
        build_application(
          annual_income:    20_000,
          property_value:   200_000,
          deposit_amount:   100_000,
          monthly_expenses: 500
        )
      end

      it 'is declined' do
        expect(result.decision).to eq('declined')
      end
    end

    context 'when monthly expenses exceed monthly income' do
      let(:application) do
        build_application(annual_income: 12_000, monthly_expenses: 2_000)
      end

      it 'is declined' do
        expect(result.decision).to eq('declined')
      end
    end
  end

  describe '#explanation' do
    context 'when approved' do
      it 'summarises the fit' do
        expect(result.explanation).to start_with('Approved')
        expect(result.explanation).to include('LTV 80.0%')
        expect(result.explanation).to include('DTI 30.0%')
      end
    end

    context 'when LTV exceeds the maximum' do
      let(:application) do
        build_application(annual_income: 100_000, deposit_amount: 10_000)
      end

      it 'names LTV' do
        expect(result.explanation).to start_with('Declined')
        expect(result.explanation).to include('LTV')
      end
    end

    context 'when DTI exceeds the maximum' do
      let(:application) { build_application(monthly_expenses: 2_500) }

      it 'names DTI' do
        expect(result.explanation).to include('DTI')
      end
    end

    context 'when the loan exceeds max borrowing' do
      let(:application) do
        build_application(
          annual_income:    20_000,
          property_value:   200_000,
          deposit_amount:   100_000,
          monthly_expenses: 500
        )
      end

      it 'names max borrowing' do
        expect(result.explanation).to include('maximum borrowing')
      end
    end

    context 'when monthly expenses exceed monthly income' do
      let(:application) do
        build_application(annual_income: 12_000, monthly_expenses: 2_000)
      end

      it 'names the expenses/income relationship' do
        expect(result.explanation).to include('monthly expenses exceed monthly income')
      end
    end

    context 'when multiple rules fail' do
      let(:application) do
        build_application(
          annual_income:    12_000,
          property_value:   250_000,
          deposit_amount:   10_000,
          monthly_expenses: 2_000
        )
      end

      it 'lists every failing rule' do
        expect(result.explanation).to include('LTV')
        expect(result.explanation).to include('DTI')
        expect(result.explanation).to include('maximum borrowing')
        expect(result.explanation).to include('monthly expenses exceed monthly income')
      end
    end
  end
end
