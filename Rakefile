# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

BasicRuby::Application.load_tasks

def create_with_sh(command, path)
  begin
    sh "#{command} > #{path}"
  rescue
    sh "rm -f #{path}"
    raise
  end
end

if defined?(before)
  before 'assets:precompile' do
    Rake::Task['js'].invoke
  end
end

file 'app/assets/javascripts/browserified.js' =>
    Dir.glob('coffee/*.coffee') do |task|
  dash_r_paths = task.prerequisites.map { |path|
    ['-r', "./#{path}"]
  }.flatten.join(' ')
  command = %W[
    node_modules/.bin/browserify
      -t coffeeify
      #{ENV['RAILS_ENV'] == 'assets' ? '-t uglifyify' : ''}
      --insert-global-vars ''
      -d
      #{dash_r_paths}
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/assets/javascripts/ast_to_bytecode_compiler.js' =>
    'lib/ast_to_bytecode_compiler.rb' do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- ast_to_bytecode_compiler
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/assets/javascripts/bytecode_interpreter.js' =>
    %w[lib/bytecode_interpreter.rb] do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- bytecode_interpreter
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/assets/javascripts/lexer.js' => 'lib/lexer.rb' do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- lexer
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/assets/javascripts/bytecode_spool.js' =>
    'lib/bytecode_spool.rb' do |task|
  command = %W[
    bundle exec opal
      -c
      -I lib
      -- bytecode_spool
  ].join(' ')
  create_with_sh command, task.name
end

file 'test/opal.js' => 'vendor/assets/javascripts/opal.js.erb' do |task|
  command = 'bundle exec erb vendor/assets/javascripts/opal.js.erb'
  create_with_sh command, task.name
end

file 'test/browserified-coverage.js' =>
  Dir.glob(['coffee/*.coffee', 'test/*.coffee']) do |task|
  dash_r_paths = task.prerequisites.map { |path|
    if path.start_with?('coffee/')
      path = path.gsub(%r[^coffee/], 'coffee-istanbul/')
      path = path.gsub(%r[\.coffee$], '.js')
      ['-r', "./#{path}"]
    end
  }.compact.flatten.join(' ')
  non_dash_r_paths = task.prerequisites.select { |path|
    path.start_with?('test/')
  }.join(' ')
  command = %W[
    rm -rf coffee-compiled coffee-istanbul
  ; cp -R coffee coffee-compiled
  ; node_modules/coffeeify/node_modules/coffee-script/bin/coffee
    -c coffee-compiled/*.coffee
  ; rm coffee-compiled/*.coffee
  ; perl -pi -w -e 's/\.coffee/\.js/g;' coffee-compiled/*.js
  ; node_modules/.bin/istanbul
      instrument coffee-compiled
      --no-compact --embed-source --preserve-comments
      -o coffee-istanbul
  ; node_modules/.bin/browserify
    --insert-global-vars '' -t coffeeify -d
    #{dash_r_paths}
    #{non_dash_r_paths}
  ].join(' ')
  create_with_sh command, task.name

  command = %W[rm -rf coffee-compiled coffee-istanbul].join(' ')
  sh command

  puts "To run tests: python -m SimpleHTTPServer; cd test; node cov_server.js;
    open http://localhost:8000/test/index.html?coverage=true"
end

task :js => %w[
  app/assets/javascripts/ast_to_bytecode_compiler.js
  app/assets/javascripts/browserified.js
  app/assets/javascripts/bytecode_interpreter.js
  app/assets/javascripts/bytecode_spool.js
  app/assets/javascripts/lexer.js
  test/opal.js
  test/browserified-coverage.js
]

task :docker => %w[
  docker/rails/Dockerfile
  docker/rails/preserve-env.conf
  docker/rails/basicruby.conf.template
] do |task|
  filenames = task.prerequisites.map { |path| path.split('/').last }
  command = ["rm -f #{filenames.join(' ')}"]
  task.prerequisites.each do |path|
    command.push "ln -s #{path}"
  end
  command.push 'docker build .'
  command.push "rm -f #{filenames.join(' ')}"
  sh command.join(";\n")
end
