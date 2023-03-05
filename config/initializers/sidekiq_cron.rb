require 'sidekiq-cron'

Sidekiq::Cron::Job.create(
  name: 'ElkhabarWorker',
  cron: '*/5 * * * *', # Run every 5 minutes
  class: 'ElkhabarWorker'
)