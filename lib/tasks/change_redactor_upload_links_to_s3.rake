namespace :fedena do

  desc "change redactor upload links to s3"
  task :local_to_s3  => :environment do
    require 'logger'
    log = Logger.new('log/local_to_s3.log')
    log.info('====================================================================')
    log.info("Starting at #{Time.now}")
    log.info('====================================================================')
    cf = Config.cloudfront_public
    modules = ["News","BlogPost","OnlineExamQuestion","OnlineExamOption","OnlineExamScoreDetail"]
    content_names = {"News"=>"content","BlogPost"=>"body","OnlineExamOption"=>"option","OnlineExamQuestion"=>"question","OnlineExamScoreDetail"=>"answer" }
    modules.each do |modul|
      obj = modul.constantize rescue nil
      if obj != nil
        content_name = content_names[modul]
        table_name = modul.classify.constantize.table_name
        objs = ActiveRecord::Base.connection.select_all("select * from #{table_name};")
        objs.each do |n|
          flag = false
          content_id = n["id"]
          content = n[content_name]
          nok = Nokogiri::HTML(content)
          results = nok.xpath("//img")
          results.each do |result|
            if(result.attributes.present? and result.attributes['src'].present?)
              srcs = result.attributes['src'].value
              regex = /redactor_uploads\/([0-9\/]*)images\//  ## regex to find partitioned redactor id
              srcs.each do |src|
                log.info(src)
                regex.match(src)
                if($1.present? and !src.include? cf)
                  id = $1.split('/').join.to_i
                  rec = ActiveRecord::Base.connection.select_one("select * from redactor_uploads where id = #{id} and image_updated_at is NULL;")
                  if(rec.present?)
                    ## updates image_updated_at column if null
                    recup = ActiveRecord::Base.connection.update("update redactor_uploads SET image_updated_at = '#{rec['updated_at']}' where id = #{id}")
                    if recup == 1
                      log.info("successfully updated column image_updated_at in redactor_upload record")
                      log.info()      #blank line
                    end
                  end
                  src_without_ts = src.split('?').first
                  regex2 = /redactor_uploads\/([0-9\/]*)\/images\/(.*)/
                  regex2.match(src_without_ts)
                  got_id = $1
                  old_filename = $2
                  part_id = ("%09d" % id).scan(/\d{3}/).join("/")
                  src_without_ts = src_without_ts.gsub("/redactor_uploads/#{got_id}/images/","/redactor_uploads/#{part_id}/images/")
                  rec_ = ActiveRecord::Base.connection.select_one("select * from redactor_uploads where id = #{id}")
                  if(rec_.present?)
                    true_filename = rec_['image_file_name']
                    src_without_ts = src_without_ts.gsub("/redactor_uploads/#{part_id}/images/#{old_filename}","/redactor_uploads/#{part_id}/images/#{true_filename}")
                  end
                  if(MultiSchool rescue nil) # checks and appends school_id if multischool & school_id is missing links
                    regex3 = /uploads\/([0-9\/]*)\/redactor_uploads/
                    regex3.match(src_without_ts)
                    if(!$1.present?)
                      log.info("missing school_id in link, hence appending it")
                      log.info()      #blank line
                      school_id = n['school_id']
                      partitioned_school_id = ("%09d" % school_id).scan(/\d{3}/).join("/")
                      src_without_ts = src_without_ts.gsub("/uploads/redactor_uploads/","/uploads/#{partitioned_school_id}/redactor_uploads/")
                    end
                  end

                  new_src = "https://#{Config.cloudfront_public}#{src_without_ts}"
                  log.info("#{src} => #{new_src}")
                  log.info()      #blank line
                  log.info()      #blank line
                  content = content.gsub(src,new_src)
                  flag = true
                elsif($1.present?)
                  id = $1.split('/').join.to_i
                  rec = ActiveRecord::Base.connection.select_one("select * from redactor_uploads where id = #{id}")
                  if(rec.present?)
                    new_cf_src = src.split('?').first
                    old_src = new_cf_src
                    regex2 = /redactor_uploads\/([0-9\/]*)\/images\/(.*)/
                    regex2.match(new_cf_src)
                    got_id = $1
                    old_filename = $2
                    part_id = ("%09d" % id).scan(/\d{3}/).join("/")
                    true_filename = CGI.escape(rec['image_file_name']).gsub('+','%2B')
                    new_cf_src = new_cf_src.gsub("/redactor_uploads/#{part_id}/images/#{old_filename}","/redactor_uploads/#{part_id}/images/#{true_filename}")
                    new_cf_src = new_cf_src.gsub("#{cf}/uploads","#{cf}/new/uploads")
                    log.info("attempted to change from #{old_src} => #{new_cf_src}")
                    content = content.gsub(old_src,new_cf_src)
                    flag = true
                  end
                end
              end
            end
          end
          if(flag)
            modul_recup = ActiveRecord::Base.connection.update("update #{table_name} SET `#{content_name}` = #{ActiveRecord::Base.connection.quote(content)} where id = #{content_id}")
            if modul_recup == 1
              log.info "successfully updated links in #{table_name} for record#id:#{content_id}"
              log.info()
            end
          end
        end
      end
    end
  end
end