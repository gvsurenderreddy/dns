require './config'

ROOT = File.dirname(__FILE__)

God.watch do |w|
  w.dir = ROOT
  w.log = CONFIG['god_log']
  w.name = "dns_service"
  w.start = "ruby service.rb"

  w.keepalive(
    memory_max: 100.megabytes,
    cpu_max: 50.percent
  )
  w.behavior(:clean_pid_file)

  w.start_if do |start|
     start.condition(:process_running) do |c|
       c.interval = 5.seconds
       c.running = false
     end
  end

end
