describe Unitpay::Service do
  let(:service) { described_class.new('public_key', 'secret_key') }

  let(:sum) { 100 }
  let(:account) { 1 }
  let(:desc) { 'Описание платежа' }
  let(:valid_sign) { 'de753ccdea0b430f80a2389f1b2e78b3' }

  describe '#calculate_sign' do
    subject { service.send(:calculate_sign, sum, account, desc) }

    it { is_expected.to eq(valid_sign) }
  end

  describe '#valid_sign?' do
    subject { service.valid_sign?(sign, sum, account, desc) }

    context 'when valid sing' do
      let(:sign) { valid_sign }

      it { is_expected.to be_truthy }
    end

    context 'when invalid sign' do
      let(:sign) { '1' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#payment_params' do
    subject { service.payment_params(sum, account, desc, options) }

    context 'when simple params' do
      let(:options) { {} }

      it { is_expected.to eq(sum: sum, account: account, desc: desc, sign: valid_sign, currency: 'RUB') }
    end

    context 'when dont use sign' do
      let(:options) { { use_sign: false } }

      it { is_expected.to eq(sum: sum, account: account, desc: desc, currency: 'RUB') }
    end

    context 'when set extra params' do
      let(:options) { { use_sign: false, locale: 'ru' } }

      it { is_expected.to eq(sum: sum, account: account, desc: desc, currency: 'RUB', locale: 'ru') }
    end
  end
end
