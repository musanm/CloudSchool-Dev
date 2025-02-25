module FedenaEmailAlert
module FedenaEmailAlertMsgParse
  def msg_parse(k)
    str={}
    k.each do |w|
      val = self.instance_eval(w)
      val = (val.is_a?(Date) || val.is_a?(DateTime)) ? format_date(val,:long) : val
      str.merge!( w.gsub(".","_").to_sym=>"#{val}")
    end
    return str
  end
end
end