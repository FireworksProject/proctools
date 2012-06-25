ROOT = File.dirname __FILE__

directory 'tmp'
directory 'dist'

task :default => :build

desc "Build Proctools"
build_deps = [
    :setup,
    'dist/package.json',
    'dist/index.js'
]
task :build => build_deps do
    puts "Built Proctools"
end

desc "Run Treadmill tests for Proctools"
task :test => [:build, :setup] do
    system 'bin/runtests'
end

task :setup => 'tmp/setup.dump' do
    puts "dev environment setup done"
end

task :clean do
    rm_rf 'tmp'
    rm_rf 'node_modules'
    rm_rf 'dist'
end

file 'tmp/setup.dump' => ['dev.list', 'tmp'] do |task|
    list = File.open(task.prerequisites.first, 'r')
    list.each do |line|
        npm_install(line)
    end
    File.open(task.name, 'w') do |fd|
        fd << "done"
    end
end

file 'dist/package.json' => ['package.json', 'dist'] do |task|
    FileUtils.cp task.prerequisites.first, task.name
    Dir.chdir 'dist'
    sh 'npm install' do |ok, id|
        ok or fail "npm could not install dependencies"
    end
    Dir.chdir ROOT
end

file 'dist/index.js' => ['index.coffee', 'dist'] do |task|
    brew_javascript task.prerequisites.first, task.name
end

def npm_install(package)
    sh "npm install #{package}" do |ok, id|
        ok or fail "npm could not install #{package}"
    end
end

def brew_javascript(source, target, node_exec=false)
    File.open(target, 'w') do |fd|
        if node_exec
            fd << "#!/usr/bin/env node\n\n"
        end
        fd << %x[./node_modules/.bin/coffee -pb #{source}]
    end
end
