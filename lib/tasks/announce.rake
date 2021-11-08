namespace :announce do

  desc 'Configure the broker destinations'
  task configure_broker: [:environment] do
    Announce.configure
    Announce.configure_broker
  end

  task verify_config: [:environment] do
    Announce.configure
    Announce.configure_broker(verify_only: true)
  end
end
