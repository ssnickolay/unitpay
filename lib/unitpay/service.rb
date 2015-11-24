module Unitpay
  class Service
    EXTRA_OPTIONS = [:locale, :hideHint, :hideBackUrl, :hideOrderCost, :hideMenu, :hideDesc, :hideOtherMethods]
    URL = 'https://unitpay.ru/pay'

    def initialize(public_key, secret_key, currency = 'RUB')
      @public_key, @secret_key, @currency = public_key, secret_key, currency
    end

    def payment_url(sum, account, desc, options = {})
      'https://unitpay.ru/pay/22760-0f8de?sum=10&account=demo&desc=Описание+платежа'
    end

    def payment_params(sum, account, desc, options = {})
      main_params(sum, account, desc, options[:use_sign]).merge(extra_params(options))
    end

    def valid_sign?(current_sign, sum, account, desc)
      current_sign == calculate_sign(sum, account, desc)
    end

    private

    attr_reader :public_key, :secret_key, :currency

    def calculate_sign(sum, account, desc)
      Digest::MD5.hexdigest( [account, currency, desc, sum, secret_key].join )
    end

    def extra_params(options)
      options.select { |key, _| EXTRA_OPTIONS.include?(key) }
    end

    def main_params(sum, account, desc, use_sign)
      use_sign = true if use_sign.nil?
      sign = use_sign ? { sign: calculate_sign(sum, account, desc) } : {}

      {
        sum: sum,
        account: account,
        desc: desc,
        currency: currency
      }.merge(sign)
    end
  end
end
