namespace :ridgepole do
  desc 'Apply database schema'
  task apply: :environment do
    ridgepole('--apply', "--file #{schema_file}")
    Rake::Task['db:schema:dump'].invoke
    Rake::Task['annotate_models'].invoke if defined?(Annotate) && Rails.env.development?
  end

  desc 'Export database schema'
  task export: :environment do
    ridgepole('--export', "--output #{Rails.root.join('db/export.Schemafile.rb')}")
  end

  private

  def schema_file
    Rails.root.join('db/Schemafile.rb')
  end

  def config_file
    Rails.root.join('config/database.yml')
  end

  def ridgepole(*options)
    command = ['bundle exec ridgepole', "--config #{config_file}", "--env #{Rails.env}", '--allow-pk-change']
    result = system (command + options).join(' ')
    raise "Command failed: #{(command + options).join(' ')}" unless result
  end
end
