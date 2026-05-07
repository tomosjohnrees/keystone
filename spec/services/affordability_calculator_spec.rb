require 'rails_helper'

RSpec.describe AffordabilityCalculator do
  subject(:result) { described_class.new(application).call }

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

  context 'when the application is well within all thresholds' do
    let(:application) { build_application }

    it 'approves' do
      expect(result.decision).to eq('approved')
    end

    it 'computes LTV, DTI, and max borrowing' do
      expect(result.ltv).to eq(80.0)
      expect(result.dti).to eq(30.0)
      expect(result.max_borrowing).to eq(270_000.0)
    end

    it 'returns an approval explanation summarising the fit' do
      expect(result.explanation).to start_with('Approved')
      expect(result.explanation).to include('LTV 80.0%')
      expect(result.explanation).to include('DTI 30.0%')
    end
  end

  context 'when LTV exceeds the maximum' do
    let(:application) do
      build_application(annual_income: 100_000, deposit_amount: 10_000)
    end

    it 'declines and names LTV in the explanation' do
      expect(result.decision).to eq('declined')
      expect(result.ltv).to eq(96.0)
      expect(result.explanation).to start_with('Declined')
      expect(result.explanation).to include('LTV')
    end
  end

  context 'when DTI exceeds the maximum' do
    let(:application) { build_application(monthly_expenses: 2_500) }

    it 'declines and names DTI in the explanation' do
      expect(result.decision).to eq('declined')
      expect(result.dti).to eq(50.0)
      expect(result.explanation).to include('DTI')
    end
  end

  context 'when loan amount exceeds max borrowing' do
    let(:application) do
      build_application(
        annual_income:    20_000,
        property_value:   200_000,
        deposit_amount:   100_000,
        monthly_expenses: 500
      )
    end

    it 'declines and names max borrowing in the explanation' do
      expect(result.decision).to eq('declined')
      expect(result.max_borrowing).to eq(90_000.0)
      expect(result.explanation).to include('maximum borrowing')
    end
  end

  context 'when monthly expenses exceed monthly income' do
    let(:application) do
      build_application(annual_income: 12_000, monthly_expenses: 2_000)
    end

    it 'declines and names the expenses/income relationship' do
      expect(result.decision).to eq('declined')
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

    it 'declines and lists every failing rule in the explanation' do
      expect(result.decision).to eq('declined')
      expect(result.explanation).to include('LTV')
      expect(result.explanation).to include('DTI')
      expect(result.explanation).to include('maximum borrowing')
      expect(result.explanation).to include('monthly expenses exceed monthly income')
    end
  end

  context 'when deposit equals property value (loan = 0)' do
    let(:application) do
      build_application(deposit_amount: 250_000, property_value: 250_000)
    end

    it 'does not raise and produces an approved result with LTV = 0' do
      expect { result }.not_to raise_error
      expect(result.ltv).to eq(0.0)
      expect(result.decision).to eq('approved')
    end
  end
end
