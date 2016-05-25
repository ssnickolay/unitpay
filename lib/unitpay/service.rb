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

    def valid_action_signature?(method, params)
      return false if params.nil? || params[:signature].nil?
      params[:signature] == calculate_action_sign(method, params)
    end

    private

    attr_reader :public_key, :secret_key, :currency, :use_sign

    def calculate_sign(sum, account, desc)
      signature_of([ account, currency, desc, sum, secret_key ])
    end

    def calculate_action_sign(method, params)
      sign_params = params.dup
      sign_params.delete(:sign)
      sign_params.delete(:signature)

      values = Hash[ sign_params.sort ].values + [ secret_key ]
      values.unshift(method)

      signature_of(values)
    end

    def signature_of(arr)
      Digest::SHA256.hexdigest(arr.join('{up}'))
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
