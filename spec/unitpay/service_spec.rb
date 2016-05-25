describe Unitpay::Service do
  let(:service) { described_class.new('public_key', 'secret_key', use_sign) }

  let(:sum) { 100 }
  let(:account) { 1 }
  let(:desc) { 'description' }
  let(:valid_signature) { '2053205d12e1b73ca6f42cf1cc9289a05aefd34f6e5ab9cb043e00494ae4b03c' }
  let(:use_sign) { true }

  describe '#calculate_sign' do
    subject { service.send(:calculate_sign, sum, account, desc) }

    it { is_expected.to eq(valid_signature) }
  end

  describe '#valid_sign?' do
    subject { service.valid_signature?(signature, sum, account, desc) }

    context 'when valid signature' do
      let(:signature) { valid_signature }

      it { is_expected.to be_truthy }
    end

    context 'when invalid signature' do
      let(:signature) { '1' }

      it { is_expected.to be_falsey }
    end
  end


  describe '#valid_action_signature?' do
    subject { service.valid_action_signature?(method, params) }

    let(:params) do
      {
        account: 'test',
        date: '2015-11-29 12:29:00',
        operator: 'mts',
        paymentType: 'mc',
        projectId: '22760',
        phone: '9001234567',
        profit: '9.5',
        sum: amount,
        orderSum: '10.00',
        signature: 'df236bfc284beb1a922ceb1f98b4ddb23ac87d5761fcc71acbf09bc06aeca720',
        orderCurrency: 'RUB',
        unitpayId: '87370'
      }
    end
    let(:method) { 'check' }

    context 'when valid' do
      let(:amount) { 10 }

      it { is_expected.to be_truthy }
    end

    context 'when valid' do
      let(:amount) { 11 }

      it { is_expected.to be_falsey }
    end

    context 'when params is nil' do
      let(:params) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when params signature is nil' do
      let(:params) { {} }

      it { is_expected.to be_falsey }
    end
  end

  describe '#payment_params' do
    let(:options) { {} }
    subject { service.payment_params(sum, account, desc, options) }

    context 'when simple params' do
      it { is_expected.to eq(sum: sum, account: account, desc: desc, signature: valid_signature, currency: 'RUB') }
    end

    context 'when dont use sign' do
      let(:use_sign) { false }

      it { is_expected.to eq(sum: sum, account: account, desc: desc, currency: 'RUB') }
    end

    context 'when set extra params' do
      let(:use_sign) { false }
      let(:options) { { locale: 'ru' } }

      it { is_expected.to eq(sum: sum, account: account, desc: desc, currency: 'RUB', locale: 'ru') }
    end
  end

  describe '#params_for_widget' do
    subject { service.params_for_widget(sum, account, desc) }

    it { is_expected.to eq(publicKey: 'public_key', sum: sum, account: account, desc: desc, signature: valid_signature, currency: 'RUB') }
  end

  describe '#payment_url' do
    subject { service.payment_url(sum, account, desc) }

    it { is_expected.to eq "https://unitpay.ru/pay/public_key?sum=100&account=1&desc=description&currency=RUB&signature=#{ valid_signature }" }
  end
end
