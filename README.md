[![Gem Version](https://badge.fury.io/rb/unitpay.svg)](https://badge.fury.io/rb/unitpay)
[![Build Status](https://travis-ci.org/ssnikolay/unitpay.svg?branch=master)](https://travis-ci.org/ssnikolay/unitpay)
[![Code Climate](https://codeclimate.com/github/ssnikolay/unitpay.svg)](https://codeclimate.com/github/ssnikolay/unitpay)
[![Test Coverage](https://codeclimate.com/github/ssnikolay/unitpay/badges/coverage.svg)](https://codeclimate.com/github/ssnikolay/unitpay/coverage)

# Unitpay

Gem для подключение к платежному шлюзу [unitpay](http://unitpay.ru).

[Документация шлюза](http://help.unitpay.ru/)

- [Установка](#installation)
- [Подключение](#setup)
- [Использование](#usage)
    - [Получение ссылки для оплаты](#payment_url)
    - [Модуль для обработки запросов от unitpay (для RubyOnRails)](#rails)
    - [Подключение виджета для карт оплат](#widget)

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
Что бы получить доступ к сервисному классу, достаточно проинициализировать его с `public` и `secret` ключами.

```ruby
service = Unitpay::Service.new('unitpay_public_key', 'unitpay_secret_key')
```

По умолчанию курс валюты выставлен в `RUB`, а использование сигнатуры в `true`.
Переопределить их можно так же при инициализации.
```ruby
use_sign, currency = false, 'RUB'
service = Unitpay::Service.new('unitpay_public_key', 'unitpay_secret_key', use_sign, currency)
```
Что бы включить проверку сигнатуры со стороны `unitpay` необходимо нажать на "замочек" в настройках вашего партнера.

![Settings](https://raw.github.com/ssnikolay/unitpay/master/unitpay.jpg)

1. Включениение проверки сигнатуры.
2. `Secret key` для инициализации `Unitpay::Service`.
3. Необходимо изменить `example.com` на адрес вашего приложения.
4. Необходимо изменить `example.com` на адрес вашего приложения.


##<a name="usage"></a> Использование

###<a name="payment_url"></a> Получение ссылки для оплаты

Что бы получить ссылку для оплаты необходимо использовать метод `payment_url`, в который нужно передать следующие параметры:

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

###<a name="rails"></a> Модуль для обработки запросов от unitpay (для RubyOnRails)

Добавьте роуты для **unitpay** (`config/routes.rb`)

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

  def pay
    # вызывается при оповещении магазина об
    # успешной оплате пользователем заказа и после проверки сигантуры.
    #
    # ВНИМАНИЕ: правильный ответ будет сгенерирован автометически, не нужно использовать (render\redirect_to)!
    # order = Order.find(params[:params][:account])
    # order.payed!
  end
  
  def error
    # вызывается при оповещении магазина об ошибке при оплате заказа.
    #
    # ВНИМАНИЕ: правильный ответ будет сгенерирован автометически, не нужно использовать (render\redirect_to)!
    # order = Order.find(params[:params][:account])
    # order.error!
  end
 
  private

  def service
    # ВНИМАНИЕ: обязательный метод! Используется при проверке сигнатуры.
    Unitpay::Service.new('unitpay_public_key', 'unitpay_secret_key')
  end
end
```

###<a name="widget"></a> Подключение виджета для карт оплат

Рассмотрим один из способов реализации случая, когда необходимо показать виджет оплаты после заполнения пользователем формы заказа.

1. Подключите на странице внешний скрипт:

```html
<script src="https://widget.unitpay.ru/unitpay.js"></script>
```

2. Добавьте обработчик формы заказа

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
            # ошибка платежного шлюза (например пользователь не завершил оплату)
            console.log('Unitpay: ошибка платежа')
        error: -> 
          # ошибка при сохранении заказа (например ошибки валидации)
          console.log('Ошибка сохранения\создания платежа (заказа)')
      })
$ ->
  unitpay = new Unitpay
  unitpay.bindEvents()

```

3. Измените контроллер так, что бы он отдавал необходимый `json` ответ

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

## Contributing

1. Fork it ( https://github.com/ssnikolay/unitpay/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
