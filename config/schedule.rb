# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end

every 10.minutes do
   runner 'Article.reindex()'
end

every :day, at: '8:00am,11:00am,1:00pm,4:00pm,7:00pm,10:00pm', roles: [:app, :web, :db] do
   rake 'crawling:scraping' 
 end
 every 10.minutes,  roles: [:app, :web, :db] do
   rake 'crawling:scraping' 
 end

# Learn more: http://github.com/javan/whenever
