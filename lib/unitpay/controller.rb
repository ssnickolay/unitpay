module Unitpay
  module Controller
    # Skip RequestForgeryProtection
    # skip_before_filter :verify_authenticity_token

    class ServiceNotImplementedError < StandardError; end
    class PayNotImplementedError < StandardError; end
    class ErrorNotImplementedError < StandardError; end

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
      raise ServiceNotImplementedError
    end

    def check
      warn 'NotImplementedError'
    end

    def pay
      raise PayNotImplementedError
    end

    def error
      raise ErrorNotImplementedError
    end

    def success_request
      render json: { result: { message: 'Запрос успешно обработан' } }
    end

    def fail_request
      render json: { error: { message: 'Неверная сигнатура' } }
    end
  end
end
