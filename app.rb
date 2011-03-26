class DmUser
  property :name, String
  property :credits, Integer, :default => 100
end 

DataMapper.setup(:default, ENV['DATABASE_URL'])
DataMapper.auto_migrate!

ENV['APP_ROOT'] ||= File.dirname(__FILE__)

class Txt10 < Sinatra::Base
  
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ['test', 'tester']
  end
  
  set :sinatra_authentication_view_path, Pathname(__FILE__).dirname.expand_path + "extend_views/"
  use Rack::Session::Cookie,             :secret => "1fe25ca9a8539ed480c21aab7a1f30fbd8c690d5ca0813673a3e3e92faff7dc8973601e3"
  use Rack::Flash
  Sinatra::SinatraAuthentication.registered(self)
  set :environment,                      ENV['APP_ENV'].to_sym
  set :public,                           'public'
  set :views,                            'views'

  API_VERSION = '2010-04-01'
  CALLER_ID   = '209-322-9828'

  ACCOUNT = Twilio::RestAccount.new(ENV['TWILIO_SID'], ENV['TWILIO_TOKEN'])

  get '/success' do params.inspect end
  get '/cancel'  do params.inspect end
  
  get '/'     do erb  :home end
  get '/send' do haml :send end

  post '/go' do
    # login_required
    #  
    # if current_user.credits < 1
    #   return false
    # end 
    #  
    # current_user.db_instance.update(:credits => current_user.credits-1)
    
    if send_sms(params[:to], params[:body])
      haml :success
    else 
      haml :failure
    end 
  end 

  def send_sms(to, message)
    d = {
      'From' => CALLER_ID,
      'To'   => to,
      'Body' => message,
    }
   
    resp = ACCOUNT.request("/#{API_VERSION}/Accounts/#{ENV['TWILIO_SID']}/SMS/Messages", 'POST', d)
    return resp.kind_of? Net::HTTPSuccess
  end 
  
end 

