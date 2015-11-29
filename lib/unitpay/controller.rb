module Unitpay
  module Controller
    # extend ActiveSupport::Concern
    #
    # included do
    #   skip_before_filter :verify_authenticity_token
    # end

    def notify
      if service.valid_notify_sign?(params[:params])
        send(params[:method])
        success_request
      else
        fail_request
      end
    end

    def success
      warn 'NotImplementedError'
    end

    def fail
      warn 'NotImplementedError'
    end

    private

    def service
      raise NotImplementedError
    end

    def check
      warn 'NotImplementedError'
    end

    def pay
      raise NotImplementedError
    end

    def error
      raise NotImplementedError
    end

    def success_request
      render json: { result: { message: 'Запрос успешно обработан' } }
    end

    def fail_request
      render json: { error: { message: 'Неверная сигнатура' } }
    end
  end
end
