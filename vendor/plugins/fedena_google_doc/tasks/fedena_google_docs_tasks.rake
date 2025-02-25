namespace :fedena_google_doc do
  desc "Install Fedena Google Doc"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_google_doc/public ."

    Dir.mkdir("#{Rails.root}/public/google_docs") unless File.exists?("#{Rails.root}/public/google_docs")
    Dir.mkdir("#{Rails.root}/public/google_uploads") unless File.exists?("#{Rails.root}/public/google_uploads")
  end
end
