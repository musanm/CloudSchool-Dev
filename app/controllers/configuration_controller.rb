#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class ConfigurationController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  FILE_EXTENSIONS = [".jpg",".jpeg",".png"]#,".gif",".png"]
  FILE_MAXIMUM_SIZE_FOR_FILE=1048576

  def settings
    @config = Configuration.get_multiple_configs_as_hash ['InstitutionName', 'InstitutionAddress', 'InstitutionPhoneNo', \
        'StudentAttendanceType', 'CurrencyType', 'ExamResultType', 'AdmissionNumberAutoIncrement','EmployeeNumberAutoIncrement', \
        'Locale','FinancialYearStartDate','FinancialYearEndDate','EnableNewsCommentModeration','DefaultCountry',\
        'TimeZone','FirstTimeLoginEnable','FeeReceiptNo','EnableSibling','PrecisionCount','DateFormat','DateFormatSeparator','StartDayOfWeek','InstitutionType', 'EnableRollNumber']
    @grading_types = Course::GRADINGTYPES
    @enabled_grading_types = Configuration.get_grading_types
    @time_zones = TimeZone.all
    @school_detail = SchoolDetail.first || SchoolDetail.new
    @countries=Country.all
    if request.post?
      Configuration.set_config_values(params[:configuration])
      session[:language] = nil unless session[:language].nil?
      @school_detail.logo = params[:school_detail][:logo] if params[:school_detail].present? and params[:school_detail][:logo].present?
      @school_detail.in_time = DateTime.new( params[:school_detail]['in_time(1i)'].to_i, params[:school_detail]['in_time(2i)'].to_i, params[:school_detail]['in_time(3i)'].to_i, params[:school_detail]['in_time(4i)'].to_i, params[:school_detail]['in_time(5i)'].to_i ) rescue nil if (params[:school_detail].present? && params[:school_detail]['in_time(1i)'].present?)
      @school_detail.email = params["school_detail"]["email"]
      @school_detail.website = params["school_detail"]["website"]
      unless @school_detail.save
        @config = Configuration.get_multiple_configs_as_hash ['InstitutionName', 'InstitutionAddress', 'InstitutionPhoneNo', \
            'StudentAttendanceType', 'CurrencyType', 'ExamResultType', 'AdmissionNumberAutoIncrement','EmployeeNumberAutoIncrement', \
            'Locale','FinancialYearStartDate','FinancialYearEndDate','EnableNewsCommentModeration','DefaultCountry','TimeZone','FirstTimeLoginEnable','EnableSibling',\
            'PrecisionCount','DateFormat','DateFormatSeparator','StartDayOfWeek','InstitutionType', 'EnableRollNumber']
        return
      end
      @current_user.clear_menu_cache
      @current_user.clear_school_name_cache(request.host_with_port)
      Configuration.clear_school_cache(@current_user)
      News.new.reload_news_bar
      flash[:notice] = "#{t('flash_msg8')}"
      redirect_to :action => "settings"  and return
    end
  end
end
