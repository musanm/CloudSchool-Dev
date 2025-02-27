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
require 'date_format'
module ApplicationHelper
  include RemarksHelper
  include DateFormater
  
  def show_header_icon
    controller_name = controller.controller_path
    "<div class='header-icon #{controller_name}-icon'></div>".html_safe
  end

  def make_breadcrumb
    target_controller = controller.controller_path
    target_action = controller.action_name
    crumb_key = "#{target_controller.to_s}_#{target_action.to_s}"
    breadcrumb crumb_key.to_sym
  end

  def render_breadcrumbs
    breadcrumb :separator => '<div class = "bread-crumb-separator"> > </div>'.html_safe,:autoroot => true,:show_root_alone => false,:link_last => false
  end

  def get_stylesheets
    @direction = (rtl?) ? 'rtl/' : ''
    stylesheets = [] unless stylesheets
    if controller.controller_path == 'user' and controller.action_name == 'dashboard'
      stylesheets << @direction+'_layouts/dashboard'
    elsif controller.controller_path == 'user' and (controller.action_name == 'login' or controller.action_name == 'set_new_password' )
      stylesheets << @direction+"_layouts/login"
    else
      stylesheets << @direction+'application'
      stylesheets << @direction+'popup.css'
    end
    stylesheets << @direction+'_styles/ui.all.css'
    stylesheets << @direction+'modalbox'
    stylesheets << @direction+'autosuggest-menu.css'
    stylesheets << @direction+'calendar'
    ["#{@direction}#{controller.controller_path}/#{controller.action_name}"].each do |ss|
      stylesheets << ss
    end
    plugin_css_overrides = FedenaPlugin::CSS_OVERRIDES["#{controller.controller_path}_#{controller.action_name}"]
    stylesheets << plugin_css_overrides.collect{|p| "#{@direction}plugin_css/#{p}"}
    FedenaPlugin::ADDITIONAL_LINKS[:icon_class_link].each do |mod|
      if FedenaPlugin.can_access_plugin?(mod[:plugin_name].to_s)
        stylesheets << @direction+(mod[:stylesheet_path].to_s)
      end
    end
    return stylesheets
  end

  def get_forgotpw_stylesheets
    @direction = (rtl?) ? 'rtl/' : ''
    stylesheets = [] unless stylesheets
    stylesheets << @direction+"_layouts/forgotpw"
    stylesheets << @direction+"_styles/style"
  end

  def get_pdf_stylesheets
    @direction = (rtl?) ? 'rtl/' : ''
    stylesheets = [] unless stylesheets
    ["#{@direction}#{controller.controller_path}/#{controller.action_name}"].each do |ss|
      stylesheets << ss
    end
    plugin_css_overrides = FedenaPlugin::CSS_OVERRIDES["#{controller.controller_path}_#{controller.action_name}"]
    stylesheets << plugin_css_overrides.collect{|p| "#{@direction}plugin_css/#{p}"}
  end

  def observe_fields(fields, options)
	  with = ""                          #prepare a value of the :with parameter
	  for field in fields
		  with += "'"
		  with += "&" if field != fields.first
		  with += field + "='+escape($('" + field + "').value)"
		  with += " + " if field != fields.last
	  end

	  ret = "";      #generate a call of the observer_field helper for each field
	  for field in fields
		  ret += observe_field(field,	options.merge( { :with => with }))
	  end
	  ret
  end

  def shorten_string(string, count)
    if string.length >= count
      shortened = string[0, count]
      splitted = shortened.split(/\s/)
      words = shortened.length
      splitted[0, words-1].join(" ") + ' ...'
    else
      string
    end
  end

  def currency_with_amount
    "#{t('amount')} (#{currency})"
  end

  #  def currency
  #    Configuration.find_by_config_key("CurrencyType").config_value
  #  end

  def pdf_image_tag(image, options = {})
    options[:src] = File.expand_path(RAILS_ROOT) + "/public/images"+ image
    tag(:img, options)
  end

  def available_language_options
    options = []
    AVAILABLE_LANGUAGES.each do |locale, language|
      options << [language, locale]
    end
    options.sort_by { |o| o[0] }
  end

  def rtl?
    if session[:language].nil?
      lan = Configuration.find_by_config_key("Locale").config_value
    else
      lan=session[:language]
    end
    @rtl ||= RTL_LANGUAGES.include? lan.to_sym
  end

  def main_menu
    Rails.cache.fetch("user_main_menu#{session[:user_id]}"){
      render :partial=>'layouts/main_menu'
    }
  end

  def current_school_detail
    SchoolDetail.first||SchoolDetail.new
  end

  def current_school_name
    Rails.cache.fetch("current_school_name/#{request.host_with_port}"){
      Configuration.get_config_value('InstitutionName')
    }
  end

  def generic_hook(cntrl,act)
    FedenaPlugin::ADDITIONAL_LINKS[:generic_hook].flatten.compact.each do |mod|
      if cntrl.to_s == mod[:source][:controller].to_s && act.to_s == mod[:source][:action].to_s
        if can_access_request? mod[:destination][:action].to_sym,mod[:destination][:controller].to_sym
          return link_to(mod[:title], :controller=>mod[:destination][:controller].to_sym,:action=>mod[:destination][:action].to_sym)
        end
      end
    end
    return ""
  end

  def generic_dashboard_hook(cntrl,act)
    dashboard_links = ""
    FedenaPlugin::ADDITIONAL_LINKS[:generic_hook].compact.flatten.each do |mod|
      if cntrl.to_s == mod[:source][:controller].to_s && act.to_s == mod[:source][:action].to_s
        if can_access_request? mod[:destination][:action].to_sym,mod[:destination][:controller].to_sym

          dashboard_links += <<-END_HTML
             <div class="link-box">
                <div class="link-heading">#{link_to t(mod[:title]), :controller=>mod[:destination][:controller].to_sym, :action=>mod[:destination][:action].to_sym}</div>
                <div class="link-descr">#{t(mod[:description])}</div>
             </div>
          END_HTML
        end
      end
    end
    return dashboard_links
  end

  def precision_label(val)
    if defined? val and val != '' and !val.nil?
      return sprintf("%0.#{precision_count}f",val)
    else
      return
    end
  end

  def precision_count
    precision_count = Configuration.get_config_value('PrecisionCount')
    precision = precision_count.to_i < 2 ? 2 : precision_count.to_i > 9 ? 8 : precision_count.to_i
    precision
  end


  def render_generic_hook
    hooks =  []
    FedenaPlugin::ADDITIONAL_LINKS[:generic_hook].compact.flatten.select{|h| h if (h[:source][:controller] == controller_name.to_s && h[:source][:action] == action_name.to_s)}.each do |hook|
      if can_access_request? hook[:destination][:action].to_sym,hook[:destination][:controller].to_sym
        h = Marshal.load(Marshal.dump(hook))
        h[:title] = t(hook[:title])
        h[:description] = t(hook[:description])
        hooks << h
      end
    end
    return hooks.to_json
  end

  def roll_number_enabled?
    @enabled ||= Configuration.get_config_value('EnableRollNumber') == "1" ? true : false
  end
  
  include WillPaginate::ViewHelpers

  def will_paginate_with_i18n(collection, options = {})
    if ([:next_label,:previous_label,"next_label","previous_label"] & options.keys).blank?
      will_paginate_without_i18n(collection, options.merge(:previous_label => I18n.t(:previous_text), :next_label => I18n.t(:next_text)))
    else
      will_paginate_without_i18n(collection, options)
    end
  end
  alias_method_chain :will_paginate, :i18n

  def error_messages_for(*params)
    opts=params.extract_options!
    unless (opts.keys & [:header_message,"header_message"]).present?
      opts.merge!(:header_message=>nil)
    end
    params.push(opts)
    super
  end
  
end
