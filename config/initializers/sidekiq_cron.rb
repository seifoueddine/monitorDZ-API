require 'sidekiq-cron'

# Run every hour
Sidekiq::Cron::Job.create(
  name: 'BiladWorkerHourly',
  cron: '0 */3 * * *', # Run every 2 hours
  class: 'BiladWorker'
)

# Run every 2 hours
Sidekiq::Cron::Job.create(
  name: 'ElkhabarWorkerBiHourly',
  cron: '0 */3 * * *', # Run every 2 hours
  class: 'ElkhabarWorker'
)