task :s3_old_data => :environment do
  require 'logger'
  log = Logger.new('log/s3_old_data.log')
  log.info('====================================================================')
  log.info("Starting at #{Time.now}")
  log.info('====================================================================')
  core_tables = ["additional_report_csvs", "students", "employees", "archived_students", "archived_employees", "school_details"]
  plugin_tables = ["applicant_addl_attachments", "applicants", "assignment_answers", "assignments", "data_exports",
    "discipline_attachments", "documents", "form_file_attachments", "gallery_photos", "group_files", "imports", "tally_export_files",
    "student_addl_attachments", "task_comments", "tasks"]
  public_tables=["redactor_uploads"]
  all_tables = core_tables + plugin_tables + public_tables
  models_marker = YAML.load_file("#{RAILS_ROOT}/lib/tasks/attachment_models.yml")

  all_tables.each do |m|
    i = models_marker[m].present? ? models_marker[m] : 0
    s3_directory = (public_tables.include?(m) ? "s3_uploads/public/" : "s3_uploads/private/" )
    if ActiveRecord::Base.connection.tables.include?(m)
      begin
        model_name = m.classify.constantize
        table_name = m
        if model_name.attachment_definitions.present?
          model_name.attachment_definitions.each do |attachment|
            attachment_name = attachment.first.to_s

            conditions = []
            conditions << "#{attachment_name}_file_name is not NULL"
            conditions << "school_id is not NULL" if MultiSchool.multi_school_models.include? m.classify
            conditions << "id > #{i}"
            sql = "select * from #{table_name} where #{conditions.join(" and ")}"
            log.info(sql)
            all_records = ActiveRecord::Base.connection.execute(sql).all_hashes
            log.info(all_records.count)
            all_records.each do |rec|
              if rec.keys.include?("school_id") and defined? MultiSchool
                MultiSchool.current_school = School.find rec["school_id"] unless rec["school_id"]==MultiSchool.current_school.try(:id)
              end
              record = model_name.send(:instantiate,rec)
              attachment_updated_at=record.send("#{attachment_name}_updated_at").try(:strftime, '%Y%m%d%H%m%S')
              attachment_new_path=record.send("#{attachment_name}").path
              attachment_old_path="#{RAILS_ROOT}/"+attachment_new_path.gsub("/#{attachment_updated_at}", "")
              if File.exist?("#{attachment_old_path}")
                file_name=File.basename(attachment_old_path)
                new_attachment_dir_path=s3_directory + attachment_new_path.gsub(file_name,'')
                FileUtils.mkdir_p(new_attachment_dir_path)
                FileUtils.cp(attachment_old_path,new_attachment_dir_path)
              end

              if record.send("#{attachment_name}").options[:styles].present?
                record.send("#{attachment_name}").options[:styles].each_pair do |k,v|
                  decoded_file_name = URI.decode(record.send("#{attachment_name}_file_name").gsub('%25','%').gsub('%2B','+'))
                  rec_id = rec["id"]
                  recup = ActiveRecord::Base.connection.update("update #{table_name} SET #{attachment_name}_file_name = '#{decoded_file_name}' where id = #{rec_id}")
                  attachment_new_path=record.send("#{attachment_name}").path(k)
                  attachment_old_path="#{RAILS_ROOT}/"+attachment_new_path.gsub("/#{attachment_updated_at}", "")
                  if File.exist?("#{attachment_old_path}")
                    file_name=File.basename(attachment_old_path)
                    new_attachment_dir_path = s3_directory + attachment_new_path.gsub(file_name,'')
                    URI.decode(new_attachment_dir_path.gsub('%25','%').gsub('%2B','+'))
                    FileUtils.mkdir_p(new_attachment_dir_path)
                    FileUtils.cp(attachment_old_path,new_attachment_dir_path)
                  end
                end
              end
              i = rec["id"]
            end
          end
        end
      rescue Exception => e
        p e
        log.info(e)
      end
    end
    models_marker[m] = i # set id of last record used for file copy
    log.info("#{m}::last id - #{i}")
    yml = YAML.dump(models_marker) # make yaml dump to update in yml file
    File.open("#{RAILS_ROOT}/lib/tasks/attachment_models.yml",'w') {|f| f.write(yml)} # update models as per last completed record
  end


end