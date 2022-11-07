Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'rubygems'
require 'sinatra'
require 'pony'
require 'sqlite3'

def get_db
  return SQLite3::Database.new 'barbershop.db'
end

configure do
  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS
    "Users"
    (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "username" TEXT,
      "phone" TEXT,
      "datestamp" TEXT,
      "barber" TEXT,
      "color" TEXT
    )'
end

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Гость '
  end
end

before '/admin' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Извините, вам нужно авторизоваться ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb :home
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  @login = params['login']
  @password = params['password']

  if @login == 'admin' && @password == 'admin'

    session[:identity] = params['login']
    where_user_came_from = session[:previous_url] || '/admin'
    redirect to where_user_came_from

  else
    @denied = 'Неправильно введён логин и (или) пароль! Попробуйте ещё...'
    erb :login_form
  end

end

get '/about' do
  erb :about
end

get '/visit' do
  erb :visit
end

post '/visit' do
  @username = params[:username]
  @phone = params[:phone]
  @date_time = params[:date_time]
  @barber = params[:master]
  @color = params[:color]

  hh = { :username => 'Вы не ввели имя',
         :phone => 'Вы не ввели телефон',
         :date_time => 'Вы не указали дату и время' }

  err = hh.select { |key,_| params[key] == ''}.values.join(',')

  if err != ''
    @error = err
    return erb :visit
  else
    db = get_db
    db.execute 'INSERT INTO Users
      (username, phone, datestamp, barber, color) VALUES (?, ?, ?, ?, ?)', [@username, @phone, @date_time, @barber, @color]

    @title = "Спасибо!"
    @message = "Уважаемый(-ая) #{@username}, вы записались к нам в Barber Shop на следующую дату и время: #{@date_time}. Вы выбрали цвет окрашивания #{@color}. Вас будет обслуживать мастер: #{@barber}. До встречи!"

    erb :message
  end

end

get '/contacts' do
  erb :contacts
end

post '/contacts' do
  @email = params[:email]
  @text = params[:text]

  hh = { :email => 'Вы не ввели email', :text => 'Вы ничего не написали в своём сообщении' }
  err = hh.select { |key,_| params[key] == ''}.values.join(',')

  if err != ''
    @error = err

    return erb :contacts

  else

      f = File.open './public/contacts.txt', 'a'
      f.write "Электронный адрес клиента:<br>\n#{@email}<br>\n Сообщение:<br>\n#{@text} <br>\n==============================<br>\n<br>\n"
      f.close

      @title = "Спасибо за обращение!"
      @message = "Наша служба поддержки обязательно свяжется с вами по указанному адресу: #{@email}"

      erb :message
  end

end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Вы не авторизованы</div>"
end

get '/admin' do
  erb :admin
end

post '/admin' do
  @datatype = params['datatype']
  @title = "#{@datatype}"

  if @datatype == "Записи в Barber Shop"
    @message = File.read './public/users.txt'

  elsif @datatype == "Обращения клиентов"
    @message = File.read './public/contacts.txt'
  else
    raise "Мы не нашли информацию по вашему запросу :'("
  end

  erb :message
end