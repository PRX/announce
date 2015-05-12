namespace :announce do

  desc 'Configure the broker destinations'
  task :configure_broker => [:environment] do |t, args|
    Announce.configure
    Announce.configure_broker
  end
end
