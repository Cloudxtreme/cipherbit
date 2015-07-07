class MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token, if: :json_request?

  PERMITTED_PARAMS = %i(source destination metadata metadata_nonce body body_nonce)

  def index
    render plain: ''
  end

  def new
  end

  def create
    Message.create(source: message_params[:source],
                   destination: message_params[:destination],
                   metadata: build_metadata,
                   body: build_body)
    redirect_to messages_url
  end

  private

  def build_metadata
    { metadata: message_params[:metadata],
      nonce: message_params[:metadata_nonce] }
  end

  def build_body
    { body: message_params[:body],
      nonce: message_params[:body_nonce] }
  end

  def message_params
    params.permit(PERMITTED_PARAMS)
  end

  def json_request?
    request.format.json?
  end
end
