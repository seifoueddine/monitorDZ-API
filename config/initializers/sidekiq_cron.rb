require 'sidekiq-cron'

Sidekiq::Cron::Job.create(
  name: 'BiladWorker',
  cron: '*/5 * * * *', # Run every 5 minutes
  class: 'BiladWorker'
)