[Time, Date].map do |klass|
  klass::DATE_FORMATS[:short_1] = proc { |time| I18n.l(time, :format => :short_dmy)}
  klass::DATE_FORMATS[:short_2] = proc { |time| I18n.l(time, :format => :short_mdy)}
  klass::DATE_FORMATS[:short_3] = proc { |time| I18n.l(time, :format => :short_ymd)}
  klass::DATE_FORMATS[:long_1] = proc { |time| I18n.l(time, :format => :long_dmy)}
  klass::DATE_FORMATS[:long_2] = proc { |time| I18n.l(time, :format => :long_mdy)}
  klass::DATE_FORMATS[:long_3] = proc { |time| I18n.l(time, :format => :long_ymd)}
  klass::DATE_FORMATS[:day] = proc { |time| time.strftime("%d")}
  klass::DATE_FORMATS[:short_day] = proc { |time| I18n.l(time, :format => :day)}
  klass::DATE_FORMATS[:long_day] = proc { |time| I18n.l(time, :format => :full_day)}
  klass::DATE_FORMATS[:short_day_and_date] = proc { |time| I18n.l(time, :format => :day_mon)}
  klass::DATE_FORMATS[:year] = proc { |time| time.strftime("%Y")}
  klass::DATE_FORMATS[:month] = proc { |time| I18n.l(time, :format => :month)}
  klass::DATE_FORMATS[:month_year] = proc { |time| I18n.l(time, :format => :month_year)}
  klass::DATE_FORMATS[:time] = proc { |time| I18n.l(time, :format => :time_p)}
end