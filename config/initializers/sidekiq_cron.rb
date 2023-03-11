require 'sidekiq-cron'

# Run every 3 hours
Sidekiq::Cron::Job.create(
  name: 'BiladWorkerHourly',
  cron: '0 */3 * * *', # Run every 3 hours
  class: 'BiladWorker'
)

# Run every 3 hours
Sidekiq::Cron::Job.create(
  name: 'ElkhabarWorkerBiHourly',
  cron: '0 */3 * * *', # Run every 3 hours
  class: 'ElkhabarWorker'
)

# Run every 2 hours
Sidekiq::Cron::Job.create(
  name: 'EnnharWorkerBiHourly',
  cron: '0 */2 * * *', # Run every 2 hours
  class: 'EnnaharWorker'
)