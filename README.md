[![Gem Version](https://badge.fury.io/rb/unitpay.svg)](https://badge.fury.io/rb/unitpay)
[![Build Status](https://travis-ci.org/ssnikolay/unitpay.svg?branch=master)](https://travis-ci.org/ssnikolay/unitpay)
[![Code Climate](https://codeclimate.com/github/ssnikolay/unitpay.svg)](https://codeclimate.com/github/ssnikolay/unitpay)
[![Test Coverage](https://codeclimate.com/github/ssnikolay/unitpay/badges/coverage.svg)](https://codeclimate.com/github/ssnikolay/unitpay/coverage)

# Unitpay

Gem для подключения к платежному шлюзу [unitpay](http://unitpay.ru).

[Документация к шлюзу](http://help.unitpay.ru/)

- [Установка](#installation)
- [Подключение](#setup)
- [Получение ссылки для оплаты](#payment_url)
- [Использование в  Rails](#rails)
- [Подключение виджета для карт оплаты](#widget)

##<a name="installation"></a> Установка

Добавьте эти строки в Gemfile вашего приложения:

```ruby
gem 'unitpay'
```

И выполните:

    $ bundle

Или установите напрямую:

    $ gem install unitpay

##<a name="setup"></a> Подключение
Чтобы получить доступ к сервисному классу, достаточно проинициализировать его с `public` и `secret` ключами.

```ruby
Unitpay::Service.new('unitpay_public_key', 'unitpay_secret_key')
```

По умолчанию курс валюты выставлен в `RUB`, а использование сигнатуры в `true`.
Переопределить их можно и при инициализации.
```ruby
use_sign, currency = false, 'RUB'
Unitpay::Service.new('unitpay_public_key', 'unitpay_secret_key', use_sign, currency)
```
Чтобы включить проверку сигнатуры со стороны `unitpay`, необходимо нажать на "замочек" в настройках вашего партнера.

![Settings](https://raw.github.com/ssnikolay/unitpay/master/unitpay.jpg)

1. Включение проверки сигнатуры.
2. `Secret key` для инициализации `Unitpay::Service`.
3. Необходимо изменить `example.com` на адрес вашего приложения.
4. Необходимо изменить `example.com` на адрес вашего приложения.

##<a name="payment_url"></a> Получение ссылки для оплаты

Чтобы получить ссылку для оплаты, необходимо использовать метод `payment_url`, в который нужно передать следующие параметры:

 Название           | Описание
--------------------|:-----------------------------------------
`sum`               | Цена, которую необходимо оплатить пользователю
`account`           | Внутренний идентификатор платежа (или заказа), однозначно определяющий его в магазине.
`desc`              | Описание платежа, отображающееся пользователю на стороне шлюза.

```ruby
sum, account, desc = 100, 1, 'description'
service = Unitpay::Service.new('unitpay_public_key', 'unitpay_secret_key')
service.payment_url(sum, account, desc)
# => 'https://unitpay.ru/pay/public_key?sum=100&account=1&desc=description...'
```

##<a name="rails"></a> Использование в  Rails

Добавьте роуты для получения запросов от **unitpay** (`config/routes.rb`)

```ruby
scope :unitpay do
  get :success, to: 'unitpay#success'
  get :fail, to: 'unitpay#fail'
  get :notify, to: 'unitpay#notify'
end
```

Создайте `app/controllers/unitpay_controller.rb` со следующим кодом:

```ruby
class UnitpayController < ApplicationController
  include Unitpay::Controller
  skip_before_filter :verify_authenticity_token
 
  def success
    # вызывается при отправке шлюзом пользователя на Success URL.
    #
    # ВНИМАНИЕ: является незащищенным действием!
    # Для выполнения действий после успешной оплаты используйте pay
  end
  
  def fail
    # вызывается при отправке шлюзом пользователя на Fail URL.
    # (во время принятия платежа возникла ошибка)
  end

  private

  def pay
    # вызывается при оповещении магазина об
    # успешной оплате пользователем заказа и после проверки сигнатуры.
    #
    # ВНИМАНИЕ: правильный ответ будет сгенерирован автоматически (не нужно использовать render\redirect_to)!
    # order = Order.find(params[:params][:account])
    # order.payed!
  end
  
  def error
    # вызывается при оповещении магазина об ошибке при оплате заказа.
    # При отсутствии логики обработки ошибок на стороне приложения оставить метод пустым.
    #
    # ВНИМАНИЕ: правильный ответ будет сгенерирован автоматически (не нужно использовать render\redirect_to)!
    # puts params[errorMessage]
    # => Текст ошибки присланный unitpay
  end

  def service
    # ВНИМАНИЕ: обязательный метод! Используется при проверке сигнатуры.
    Unitpay::Service.new('unitpay_public_key', 'unitpay_secret_key')
  end
end
```

[Описание параметров, передаваемых при запросе.
](http://help.unitpay.ru/article/35-confirmation-payment)

### Исключения при обработки зароса

Важно понимать, что до вызова метода `pay` происходит проверка только сигнатуры. Проверка на соответствие суммы оплаты и суммы заказа остается на вашей совести. Для удобства обработки таких ситуаций существует зарезервирваное исключение `Unitpay::Controller::ErrorMethodNotImplemented`.

Пример:

```ruby
def pay
  order = Order.find(params[:params][:account])
  if order.total_cost == params[:params][:sum]
    order.payed!
  else
    raise Unitpay::Controller::ErrorMethodNotImplemented
  end
end
```

##<a name="widget"></a> Подключение виджета для карт оплаты

Рассмотрим один из способов реализации случая, когда необходимо показать виджет оплаты после заполнения пользователем формы заказа.

- Подключите на странице внешний скрипт:

```html
<script src="https://widget.unitpay.ru/unitpay.js"></script>
```

- Добавьте обработчик формы заказа:

**unitpay.js.coffe**
```coffee
class Unitpay
  bindEvents: ->
    @handleAfterSubmitForm()

  handleAfterSubmitForm: ->
    $('#id-your-form').submit (e) ->
      e.preventDefault()
      tryUnitpay() # при сабмите формы пытаемся получить параметры для виджета

  tryUnitpay = ->
    $.ajax({
      type: 'POST',
      dataType: 'json'
      url: '/orders' # любой другой путь сохранения\создания вашего платежа (заказа). Не забудьте добавить его в routes.rb
      data: $('#id-your-form').serialize(),
      success: (data) ->
        payment = new UnitPay()
        payment.createWidget(data)
        payment.success ->
          console.log('Unitpay: успешный платеж')
        payment.error ->
          # ошибка платежного шлюза (например, пользователь не завершил оплату)
          console.log('Unitpay: ошибка платежа')
      error: ->
        # ошибка при сохранении заказа (например, ошибки валидации)
        console.log('Ошибка сохранения\создания платежа (заказа)')
    })
$ ->
  unitpay = new Unitpay
  unitpay.bindEvents()

```

- Измените контроллер так, чтобы он отдавал необходимый `json` ответ:

**orders_controller.rb**
```ruby
class OrdersController < ApplicationController
  def create
    order = Order.new(permitted_params)
    if order.save
      render json: unitpay_service.params_for_widget(order.total_cost, order.id, order.description)
    else
      render json: order.errors, status: :unprocessable_entity
    end
  end
  
  private
  
  def unitpay_service
    # Внимание: не храните ключи в открытом виде в репозитории.
    # используйте  конфигурационные файлы (https://github.com/binarylogic/settingslogic) 
    Unitpay::Service.new('public_key', 'secret_key')
  end
  
  def permitted_params
    # используйте strong params
  end
end
```

## Contributing

1. Fork it ( https://github.com/ssnikolay/unitpay/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
