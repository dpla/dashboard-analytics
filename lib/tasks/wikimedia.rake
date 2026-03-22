namespace :wikimedia do
  desc "Rebuild the Wikimedia cache from the CIM API"
  task rebuild_cache: :environment do
    puts "Starting Wikimedia cache rebuild..."
    WikimediaCacheBuilder.rebuild
    puts "Done."
  end
end
