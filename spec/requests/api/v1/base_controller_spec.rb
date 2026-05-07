require 'rails_helper'

# A plain ActiveModel object so the spec can raise RecordInvalid without
# touching the database.
class StubRecord
  include ActiveModel::Model
  attr_accessor :name
  validates :name, presence: true
end

module Api
  module V1
    class StubsController < BaseController
      def not_found
        raise ActiveRecord::RecordNotFound
      end

      def unprocessable
        record = StubRecord.new
        record.validate
        raise ActiveRecord::RecordInvalid.new(record)
      end

      def bad_request
        params.require(:required_key)
      end
    end
  end
end

RSpec.describe 'Api::V1::BaseController error handling', type: :request do
  before(:all) do
    Rails.application.routes.draw do
      namespace :api do
        namespace :v1 do
          get 'stubs/not_found',     to: 'stubs#not_found'
          get 'stubs/unprocessable', to: 'stubs#unprocessable'
          get 'stubs/bad_request',   to: 'stubs#bad_request'
        end
      end
    end
  end

  after(:all) do
    Rails.application.reload_routes!
  end

  describe 'when the action raises ActiveRecord::RecordNotFound' do
    it 'returns 404 with a not_found error body' do
      get '/api/v1/stubs/not_found'

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq('error' => 'not_found')
    end
  end

  describe 'when the action raises ActiveRecord::RecordInvalid' do
    it 'returns 422 with a JSON errors body shaped { errors: { field: [messages] } }' do
      get '/api/v1/stubs/unprocessable'

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq('errors' => { 'name' => [ "can't be blank" ] })
    end
  end

  describe 'when the action raises ActionController::ParameterMissing' do
    it 'returns 400 with a bad_request error body and message naming the missing key' do
      get '/api/v1/stubs/bad_request'

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq('bad_request')
      expect(response.parsed_body['message']).to include('required_key')
    end
  end
end
