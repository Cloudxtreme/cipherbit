class MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token, if: :json_request?

  PERMITTED_PARAMS = %i(source destination metadata body)

  # Actions that return the browser UI

  def inbox
  end

  def view
    id = params.permit(:id)[:id]
    message_option = Message.where(id: id)
    if message_option.blank?
      render file: "#{Rails.root}/public/404.html", status: :not_found
    end
    @message = message_option.first
  end

  def new
  end

  # Actions that return JSON (API calls)

  def index
    key = params[:key]
    render json: Message.where(destination: key)
  end

  def show
    id = params[:id].to_i
    render json: Message.find(id)
  end

  def create
    Message.create(source: message_params[:source],
                   destination: message_params[:destination],
                   metadata: message_params[:metadata],
                   body: message_params[:body])
    redirect_to :inbox_messages
  end

  private

  def message_params
    @message_params ||= validate_params
  end

  def validate_params
    params.permit(PERMITTED_PARAMS)
  end

  def json_request?
    request.format.json?
  end
end
