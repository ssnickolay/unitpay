describe Unitpay::Controller do
  class TestController
    include Unitpay::Controller
    attr_reader :response

    def render(response)
      @response = response
    end

    def params
      {}
    end

    def service
      Unitpay::Service.new('public_key', 'secret_key')
    end
  end

  RSpec::Matchers.define :be_success do |_|
    match do |actual|
      expect(actual).to eq(json: { result: { message: 'Запрос успешно обработан' } })
    end
  end

  RSpec::Matchers.define :be_fail do |_|
    match do |actual|
      expect(actual).to eq(json: { error: { message: 'Неверная сигнатура' } })
    end
  end

  describe '#sussecc' do
    it 'should raise error' do
      expect_any_instance_of(TestController).to receive(:warn).with('NotImplementedError')
      TestController.new.success
    end
  end

  describe '#fail' do
    it 'should raise error' do
      expect_any_instance_of(TestController).to receive(:warn).with('NotImplementedError')
      TestController.new.fail
    end
  end

  describe '#notify' do
    let(:params) do
      {
        method: method,
        params: {
          account: 'test',
          date: '2015-11-29 12:29:00',
          operator: 'mts',
          paymentType: 'mc',
          projectId: '22760',
          phone: '9001234567',
          profit: '9.5',
          sum: sum,
          orderSum: '10.00',
          sign: '22905cade6376990a030b2200f664842',
          orderCurrency: 'RUB',
          unitpayId: '87370'
        }
      }
    end

    let(:sum) { 10 }

    let(:response) do
      controller = TestController.new
      controller.notify
      controller.response
    end

    before do
      allow_any_instance_of(TestController).to receive(:params).and_return(params)
    end

    subject { response }

    describe '#check' do
      let(:method) { 'check' }

      context 'when valid signature' do
        before { expect_any_instance_of(TestController).to receive(:check) }

        it { is_expected.to be_success }
      end

      context 'when invalid signature' do
        let(:sum) { 11 }

        it { is_expected.to be_fail }
      end
    end

    describe '#pay' do
      let(:method) { 'pay' }

      it 'should raise not implemented error' do
        controller = TestController.new
        expect{ controller.notify }.to raise_error(Unitpay::Controller::PayMethodNotImplemented)
      end

      context 'when valid signature' do
        before { expect_any_instance_of(TestController).to receive(:pay) }

        it { is_expected.to be_success }
      end

      context 'when invalid signature' do
        let(:sum) { 11 }

        it { is_expected.to be_fail }
      end
    end

    describe '#error' do
      let(:method) { 'error' }

      it 'should raise not implemented error' do
        controller = TestController.new
        expect{ controller.notify }.to raise_error(Unitpay::Controller::ErrorMethodNotImplemented)
      end

      context 'when valid signature' do
        before { expect_any_instance_of(TestController).to receive(:error) }

        it { is_expected.to be_success }
      end
    end
  end
end
