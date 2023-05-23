# frozen_string_literal: true

require 'English'
require 'pathname'
require 'timeout'

def get_env_variable(key)
  ENV[key].nil? || ENV[key] == '' ? nil : ENV[key]
end

def run_command(cmd)
  puts "@@[command] #{cmd}"
  output = `#{cmd}`
  raise "Failed to execute - #{cmd}" unless $CHILD_STATUS.success?

  output
end

def list_devices
  output = run_command('adb devices').split("\n")
  return [] unless output.count > 1

  output.drop(1).map { |line| line.split("\t").first }
end

def installed_avd?(name)
  emulators = run_command("#{emulator_path} -list-avds").split("\n")
  emulators.include? name
end

def adb_prop_eq?(prop, expected)
  cmd = "adb shell getprop #{prop}"
  ret = `#{cmd} 2>&1`.strip
  puts "getprop #{prop} : '#{ret}'"
  ret == expected
end

def emulator_ready?
  adb_prop_eq?('dev.bootcomplete',       '1')       or return false
  adb_prop_eq?('sys.boot_completed',     '1')       or return false

  (adb_prop_eq?('service.bootanim.exit', '1') ||
      adb_prop_eq?('init.svc.bootanim', 'stopped')) or return false
  true
end

def emulator_path
  android_home = get_env_variable('ANDROID_HOME') || abort('Missing ANDROID_HOME variable.')
  Pathname.new(android_home).join('emulator/emulator').to_s
end

def wait_emulator
  attempt = 1
  cool_down = 10
  loop do
    puts "[I] Attempt ##{attempt}"
    break if emulator_ready?

    puts "[I] Waiting #{cool_down} seconds before next attempt"
    attempt += 1
    sleep cool_down
  end
end

def wait_for_emulator(name, duration)
  begin
    Timeout.timeout(duration) do
      wait_emulator
    end
  rescue Timeout::Error
    puts "(X) Starting #{name} timed out"
    return false
  end
  true
end

def start_emulator(name, arguments)
  run_command('adb start-server')
  cmd = "#{emulator_path} -avd #{name} #{arguments} &"
  result = system(cmd)
  puts result
  sleep 5
end

def start_and_wait_for_emulator(name, arguments, duration)
  unless installed_avd?(name)
    puts "(X) Emulator '#{name}' not found"
    return false
  end
  start_emulator(name, arguments)
  status = wait_for_emulator(name, duration)
  puts "[I] Emulator #{name} is ready" if status == true
  status
end

def install_apk()
  apk_path = get_env_variable('AC_SIGNED_APK_PATH')
  if apk_path && File.exist?(apk_path)
    puts "Installing APK file: #{apk_path}"
    run_command("adb install #{apk_path}")
  end
end

emulator_name = get_env_variable('AC_TEST_DEVICE') || 'Pixel_3a'
wait_period = get_env_variable('AC_TEST_ADB_WAIT_SECONDS') || '300'
arguments = get_env_variable('AC_TEST_ADB_ARGUMENTS')

status = start_and_wait_for_emulator(emulator_name, arguments, wait_period.to_i)
if status == true
  puts "[I] Running emulators #{list_devices}"
  install_apk()
else
  exit(1)
end
