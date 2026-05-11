require 'rails_helper'

RSpec.describe 'Api::V1::Assessments', type: :request do
  describe 'GET /api/v1/mortgage_applications/:mortgage_application_id/assessment' do
    let(:application) { create(:mortgage_application) }

    context 'when the assessment is pending' do
      let!(:assessment) { application.create_assessment! }

      it 'returns 200 with the assessment in pending state' do
        get "/api/v1/mortgage_applications/#{application.id}/assessment",
            headers: api_auth_headers

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['status']).to eq('pending')
        expect(body['decision']).to be_nil
        expect(body['ltv']).to be_nil
      end
    end

    context 'when the assessment is completed' do
      let!(:assessment) do
        application.create_assessment!
        perform_enqueued_jobs { AssessAffordabilityJob.perform_later(application.assessment) }
        application.assessment
      end

      it 'returns 200 with the populated result' do
        get "/api/v1/mortgage_applications/#{application.id}/assessment",
            headers: api_auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          AssessmentSerializer.new(assessment.reload).as_json
        )
      end
    end

    context 'when the application does not exist' do
      it 'returns 404' do
        get '/api/v1/mortgage_applications/0/assessment', headers: api_auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
