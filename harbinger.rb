#!/usr/bin/env ruby

require 'aws-sdk'
require 'syslog'

config_file = File.join(File.dirname(__FILE__), "config.yml")
unless File.exist?(config_file)
  puts <<END
To run the samples, put your credentials in config.yml as follows:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY

END
  exit 1
end

config = YAML.load(File.read(config_file))
unless config.kind_of?(Hash)
  puts <<END
config.yml is formatted incorrectly.  Please use the following format:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY

END
  exit 1
end


# Determine the instance's age
def check_age(launchtime)
  now = Time.now.to_i
  launchtime = launchtime.to_i
  diff = now - launchtime

  if diff >= 172800
    return '2-day'
  elsif diff >= 86400
    return '1-day'
  end
end

# Determine that the instance has the appropriate tags
def check_tags(tags)
  if tags['Purpose'] == 'Continuous Integration' && tags['Environment'] == 'QA'
    return 'yes'
  else
    return 'no'
  end
end

def log(message)
  Syslog.open($0, Syslog::LOG_PID | Syslog::LOG_CONS) { |s| s.info message }
end


AWS.config(config)
ec2 = AWS.ec2

i = ec2.instances
log('Starting...')

i.each do |instance|

  # Ensure that we're dealing with a Jenkins CI QA container
  # Else, skip this instance
  unless tagged = check_tags(instance.tags) == 'yes'
    next
  end

  # If the instance is running and is over a day old, stop it
  if instance.status == 'running' && check_age(instance.launch_time) == '1-day'
    log('Instance ' + instance.tags['Name'] + ' (' + instance.id + ') is over 1 day old and is still running.  Stopping it.')
    ec2.instances.stop[instance.id]
  end

  # If the instance is stopped and is over two days old, terminate it
  if instance.status == 'stopped' && check_age(instance.launch_time) == '2-day'
    log('Instance ' + instance.tags['Name'] + ' (' + instance.id + ') is over 2 days old and is stopped.  Terminating it.')
    ec2.instances.terminate[instance.id]
  end

end

log('Finished...')
