module Unitpay
  class Service
    EXTRA_OPTIONS = [:locale, :hideHint, :hideBackUrl, :hideOrderCost, :hideMenu, :hideDesc, :hideOtherMethods]
    URL = 'https://unitpay.ru/pay'

    def initialize(public_key, secret_key, use_sign = true, currency = 'RUB')
      @public_key, @secret_key, @use_sign, @currency = public_key, secret_key, use_sign, currency
    end

    def payment_url(sum, account, desc, options = {})
      URI.escape(url(sum, account, desc, options))
    end

    def payment_params(sum, account, desc, options = {})
      main_params(sum, account, desc).merge(extra_params(options))
    end

    def params_for_widget(sum, account, desc)
      main_params(sum, account, desc).merge(publicKey: public_key)
    end

    def valid_signature?(current_sign, sum, account, desc)
      current_sign == calculate_sign(sum, account, desc)
    end

    def valid_notify_signature?(params)
      params[:signature] == calculate_notify_sign(params)
    end

    private

    attr_reader :public_key, :secret_key, :currency, :use_sign

    def calculate_sign(sum, account, desc)
      Digest::SHA256.hexdigest([ account, currency, desc, sum, secret_key ].join('{up}'))
    end

    def calculate_notify_sign(params)
      params.delete(:sign)
      params.delete(:signature)
      params.delete(:method)
      values = Hash[ params.sort ].values + [ secret_key ]

      Digest::SHA256.hexdigest(values.join('{up}'))
    end

    def main_params(sum, account, desc)
      sign = use_sign ? { signature: calculate_sign(sum, account, desc) } : {}

      {
        sum: sum,
        account: account,
        desc: desc,
        currency: currency
      }.merge(sign)
    end

    def extra_params(options)
      options.select { |key, _| EXTRA_OPTIONS.include?(key) }
    end

    def url(sum, account, desc, options)
      "#{ URL }/#{ public_key }?#{ to_query(payment_params(sum, account, desc, options)) }"
    end

    def to_query(hash)
      hash.map { |k, v| "#{k}=#{v}" }.join('&')
    end
  end
end
