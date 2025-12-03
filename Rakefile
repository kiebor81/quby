# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = false
  # Disable Minitest plugins to avoid loading Rails plugins
  ENV['MT_NO_PLUGINS'] = '1'
end

task default: :test

# YARD documentation task
begin
  require 'yard'
  
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files = ['lib/**/*.rb']
    t.options = ['--markup', 'markdown', '--markup-provider', 'kramdown']
  end
  
  desc 'Generate YARD documentation and open in browser'
  task :docs => :doc do
    doc_path = File.expand_path('doc/index.html')
    
    opened = false
    
    # Check if running in WSL
    is_wsl = File.exist?('/proc/version') && File.read('/proc/version').include?('microsoft')
    
    if RUBY_PLATFORM =~ /darwin/
      # macOS
      opened = system('open', doc_path)
    elsif is_wsl
      # WSL - convert Linux path to Windows path and open with Windows browser
      windows_path = `wslpath -w '#{doc_path}'`.strip
      opened = system('cmd.exe', '/c', 'start', windows_path) ||
               system('wslview', doc_path) ||
               system('explorer.exe', windows_path)
    elsif RUBY_PLATFORM =~ /linux/
      # Native Linux - try multiple browser launchers
      ['xdg-open', 'sensible-browser', 'firefox', 'google-chrome', 'chromium'].each do |cmd|
        if system("which #{cmd} > /dev/null 2>&1")
          opened = system(cmd, doc_path)
          break if opened
        end
      end
    elsif RUBY_PLATFORM =~ /mingw|mswin/
      # Native Windows
      opened = system('start', doc_path)
    end
    
    if opened
      puts "Documentation generated and opened in browser!"
    else
      puts "Documentation generated at: #{doc_path}"
      puts "Open it manually in your browser."
    end
  end
rescue LoadError
  # YARD not available
  task :doc do
    puts "YARD is not available. Install it with: gem install yard kramdown"
  end
end

