module WeatherAlerts
  module Forecast
    def alerts
      forecast.fetch('alerts')
    end

    def forecast
      @forecast ||= memcache.get 'forecast'
      @forecast ||= ::Forecast::IO.forecast(latitude, longitude, params: { exclude: ['currently', 'minutely', 'hourly', 'daily', 'flags'] } )
      memcache.add 'forecast', @forecast
      @forecast
    end
  end

  module Google
    require 'glass'
    require 'glass/locations/location'
    ::Glass::Mirror.client_id     = ENV['GLASS_CLIENT_ID']
    ::Glass::Mirror.client_secret = ENV['GLASS_CLIENT_SECRET']
    ::Glass::Mirror.redirect_uri  = ENV['GLASS_REDIRECT_URI'] || 'http://localhost:8080'
    # Glass::Mirror.scopes      += [# Add other requested scopes]

    def latitude
      ENV['GEO_LAT'] || '35.62'
      # ::Glass::Location.latitude
    end

    def longitude
      ENV['GEO_LON'] || '-97.62'
      # ::Glass::Location.longitude
    end
  end
end

class App < Hobbit::Base
  include Hobbit::Render
  use Rack::Static, root: 'public', urls: ['/javascripts', '/stylesheets']
  if ENV['RACK_ENV'] == 'development'
    require 'ap'
    use Rack::ShowExceptions
  end

  include WeatherAlerts::Forecast
  include WeatherAlerts::Google

  # Configure Forecast
  Forecast::IO.api_key = ENV['FORECAST_IO_API_KEY']

  def memcache
    @dalli_client ||= Dalli::Client.new
  end

  get '/' do
    render 'views/layout.html.erb' do
      render 'views/glass.html.erb'
    end
  end
end
