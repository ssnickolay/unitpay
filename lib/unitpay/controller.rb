module Unitpay
  module Controller
    # Skip RequestForgeryProtection
    # skip_before_filter :verify_authenticity_token

    class ServiceNotImplemented < StandardError; end
    class PayMethodNotImplemented < StandardError; end
    class ErrorMethodNotImplemented < StandardError; end
    class RuntimeException < StandardError; end

    def notify
      if service.valid_notify_sign?(params[:params])
        send(params[:method])
        success_request
      else
        fail_request
      end
    rescue RuntimeException
      fail_request
    end

    def success
      warn 'NotImplementedError'
    end

    def fail
      warn 'NotImplementedError'
    end

    private

    def service
      raise ServiceNotImplemented
    end

    def check
      warn 'NotImplementedError'
    end

    def pay
      raise PayMethodNotImplemented
    end

    def error
      raise ErrorMethodNotImplemented
    end

    def success_request
      render json: { result: { message: 'Запрос успешно обработан' } }
    end

    def fail_request
      render json: { error: { message: 'Неверная сигнатура' } }
    end
  end
end
