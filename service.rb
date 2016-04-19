require 'rubydns'
require 'sinatra'
require 'json'
require 'rack'
require 'logger'
require './config'

set :environment, :production

LOGGER = Logger.new(CONFIG['dns_log'])

# cached dns mappings
Mappings = JSON.parse(File.read(CONFIG['lookup'])) rescue {}

# http server that listens to dns A record registry
class DNSUpdater < Sinatra::Base
  get '/' do
    if !params[:hostname].nil? && !params[:ip].nil? && params[:hostname] =~ CONFIG['domain_pattern']
      Mappings[params[:hostname]] = params[:ip]
      File.open(CONFIG['lookup'], 'w') {|f| f.write(JSON.dump(Mappings)) }
      LOGGER.info("Created mapping: #{params[:hostname]} => #{params[:ip]}")
    end
  end
end

Thread.new do
  LOGGER.info('DNS Updater started. Reading existing DNS mappings...')
  LOGGER.info(Mappings)

  logger = Logger.new(CONFIG['http_log'])
  access_log = [
    [logger, "%h %l %u %t \"%r\" %s %b"],
    [logger, "%{Referer}i -> %U"]
  ]
  Rack::Handler::WEBrick.run DNSUpdater, Port: CONFIG['downstream']['http'].to_i, AccessLog: access_log
end

# setup and run the dns service
INTERFACES = [
  [:udp, CONFIG['downstream']['host'], CONFIG['downstream']['tcp'].to_i],
  [:tcp, CONFIG['downstream']['host'], CONFIG['downstream']['udp'].to_i]
]

Name = Resolv::DNS::Name
IN = Resolv::DNS::Resource::IN

UPSTREAM = RubyDNS::Resolver.new([
  [:udp, CONFIG['upstream']['host'], CONFIG['upstream']['tcp'].to_i],
  [:tcp, CONFIG['upstream']['host'], CONFIG['upstream']['udp'].to_i]
])

RubyDNS::run_server(:listen => INTERFACES, :logger => Logger.new("/dev/null")) do
  match(CONFIG['domain_pattern'], IN::A) do |transaction, host|
    ip = Mappings["#{host}"]
    if ip.nil?
      transaction.fail!(:NXDomain)
    else
      transaction.respond!(ip)
    end
  end

  #passthrough
  otherwise do |transaction|
    transaction.passthrough!(UPSTREAM)
  end
end


