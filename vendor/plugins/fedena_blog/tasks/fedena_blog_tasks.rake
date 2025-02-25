namespace :fedena_blog do
  desc "Install Fedena Blog Module"
  task :install do
    #system "rsync -ruv --exclude=.svn vendor/plugins/fedena_blog/db/migrate db"
    system "rsync -ruv --exclude=.svn vendor/plugins/fedena_blog/public ."
  end
end
