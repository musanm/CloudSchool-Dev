module DateFormater

  def format_date(date,*params)
    @date_format ||= DateFormat.new
    opts=params.extract_options!

    # date format is picked from configuration
    # full or short date format is as per format
    # default date format is short format
    format = opts[:format] || :short

    @date_format.format(date,format)
  end

  def date_format
    @date_format ||= DateFormat.new
    @date_format.get_format
  end

end
::ActiveRecord::Base.send :include, DateFormater
::ActiveRecord::Base.send :extend, DateFormater