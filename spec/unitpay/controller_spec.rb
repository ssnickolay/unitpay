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

  RSpec::Matchers.define :be_fail do |expected = 'Неверная сигнатура'|
    match do |actual|
      expect(actual).to eq(json: { error: { message: expected } })
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
          signature: signature,
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
      let(:signature) { 'df236bfc284beb1a922ceb1f98b4ddb23ac87d5761fcc71acbf09bc06aeca720' }

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
      let(:signature) { '997061638b15026374257f483e3b55b81727fe53fd329fdb34fda4dc2ab3e245' }

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

      context 'when pay raise runtime exception' do
        before do
          expect_any_instance_of(TestController).to receive(:pay).and_raise(Unitpay::Controller::RuntimeException)
        end

        it { is_expected.to be_fail('Unitpay::Controller::RuntimeException') }
      end
    end

    describe '#error' do
      let(:method) { 'error' }
      let(:signature) { '9b3952eb48958f151a86964382b1808f5a9f969ecd6da204c2243b250c3edeb8' }

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
