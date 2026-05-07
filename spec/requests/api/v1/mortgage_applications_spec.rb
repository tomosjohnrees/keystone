require 'rails_helper'

RSpec.describe 'Api::V1::MortgageApplications', type: :request do
  describe 'POST /api/v1/mortgage_applications' do
    let(:valid_attributes) do
      {
        annual_income: '60000.00',
        monthly_expenses: '1500.00',
        deposit_amount: '50000.00',
        property_value: '250000.00',
        term_years: 25
      }
    end

    context 'with a valid payload' do
      subject(:create_request) do
        post '/api/v1/mortgage_applications',
             params: { mortgage_application: valid_attributes },
             as: :json
      end

      it 'persists a new mortgage application' do
        expect { create_request }.to change(MortgageApplication, :count).by(1)
      end

      it 'returns 201 Created' do
        create_request
        expect(response).to have_http_status(:created)
      end

      it 'returns the serialized application in the response body' do
        create_request

        application = MortgageApplication.last
        expect(response.parsed_body).to eq(
          MortgageApplicationSerializer.new(application).as_json
        )
      end
    end

    context 'when the mortgage_application key is missing' do
      it 'returns 400 with a bad_request error body' do
        post '/api/v1/mortgage_applications',
             params: {},
             as: :json

        expect(response).to have_http_status(:bad_request)
        body = response.parsed_body
        expect(body['error']).to eq('bad_request')
        expect(body['message']).to include('mortgage_application')
      end
    end
  end

  describe 'GET /api/v1/mortgage_applications/:id' do
    let(:application) { create(:mortgage_application) }

    it 'returns 200 OK' do
      get "/api/v1/mortgage_applications/#{application.id}"
      expect(response).to have_http_status(:ok)
    end

    it 'returns the serialized application in the response body' do
      get "/api/v1/mortgage_applications/#{application.id}"

      expect(response.parsed_body).to eq(
        MortgageApplicationSerializer.new(application).as_json
      )
    end
  end
end
