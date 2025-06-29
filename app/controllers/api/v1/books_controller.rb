class Api::V1::BooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def search
    service = Api::V1::Books::SearchService.new params
    if service.call
      render json: {
        books: service.books,
        total: service.books.count,
        query: service.query,
        limit: service.limit
      }, status: :ok
    else
      render json: {
        message: service.message
      }, status: :internal_server_error
    end
  end
end
