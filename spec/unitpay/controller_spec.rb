describe Unitpay::Controller do
  class TestController
    include Unitpay::Controller
    attr_reader :request

    def render(request)
      @request = request
    end

    def params
      {}
    end

    def service
      Unitpay::Service.new('public_key', 'secret_key')
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

    before do
      allow_any_instance_of(TestController).to receive(:params).and_return(params)
    end

    describe '#check' do
      let(:method) { 'check' }

      context 'when valid signature' do
        let(:sum) { 10 }

        it 'should render success request' do
          expect_any_instance_of(TestController).to receive(:check)
          controller = TestController.new
          controller.notify
          expect(controller.request).to eq(json: { result: { message: 'Запрос успешно обработан' } })
        end
      end

      context 'when invalid signature' do
        let(:sum) { 11 }

        it 'should render fail request' do
          controller = TestController.new
          controller.notify
          expect(controller.request).to eq(json: { error: { message: 'Неверная сигнатура' } })
        end
      end
    end

    describe '#pay' do
      let(:method) { 'pay' }

      context 'when valid signature' do
        let(:sum) { 10 }

        it 'should render success request' do
          controller = TestController.new
          expect{ controller.notify }.to raise_error(Unitpay::Controller::PayNotImplementedError)
        end
      end
    end

    describe '#error' do
      let(:method) { 'error' }

      context 'when valid signature' do
        let(:sum) { 10 }

        it 'should render success request' do
          controller = TestController.new
          expect{ controller.notify }.to raise_error(Unitpay::Controller::ErrorNotImplementedError)
        end
      end
    end
  end
end
