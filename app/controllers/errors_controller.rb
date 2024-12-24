class ErrorsController < ApplicationController
  def route_not_found
    render json: {
      error: "Route not found",
      path: request.path,
      method: request.method
    }, status: :not_found
  end
end
