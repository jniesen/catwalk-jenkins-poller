require 'httparty'
require 'json'
require 'sinatra'

class SocketServer
  include HTTParty
  headers 'Content-Type' => 'application/json'

  def initialize(url)
    self.class.base_uri(url)
  end

  def send_status(json_payload)
    self.class.post("/status", { body: json_payload })
  end
end

set :server, 'thin'
set :port, ENV['CATWALK_POLLER_PORT']
set :socket_server_url, ENV['CATWALK_SOCKET_SERVER_URL']
set :socket_server, SocketServer.new(settings.socket_server_url)

set :jobs, {}

get '/' do
  'hello'
end

post '/register' do
  pass unless json_request?(request)

  jobs = settings.jobs
  json = JSON.parse(request.body.read)
  team = json['team']
  project = json['project']
  job_name = json['jobName']
  build_url = json['buildUrl']

  h_team = jobs[team].nil? ? jobs[team] = {} : jobs[team]
  h_project = h_team[project].nil? ? h_team[project] = [] : h_team[project]
  h_project.push({ job_name: job_name, build_url: build_url })

  settings.socket_server.send_status(jobs.to_json)
end

private
def json_request?(request)
  json_request = 'application/json'

  request.accept?(json_request) || request.content_type == json_request
end

