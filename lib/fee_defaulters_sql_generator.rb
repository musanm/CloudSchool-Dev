module FeeDefaultersSqlGenerator

  def sql_for_finance
    conditions = ["`fc`.`is_deleted` = 0","fc.due_date < '#{Date.today}'","ff.balance>0","st.id IS NOT NULL"]
    conditions << "ff.school_id=#{MultiSchool.current_school.id}" if defined?(MultiSchool)
    where_condition = conditions.join(" AND ")
    finance="(SELECT ff.student_id student_id,CONCAT('f',fc.id) collection_id, fc.due_date due_date, fc.name collection_name, ff.balance balance, ff.batch_id batch_id FROM `finance_fees` ff LEFT OUTER JOIN students st on st.id=ff.student_id INNER JOIN `finance_fee_collections` fc ON `fc`.id = `ff`.fee_collection_id WHERE (#{where_condition}))"
    finance
  end

  def sql_for_transport
    conditions = ["`fc`.`is_deleted` = 0","fc.due_date < '#{Date.today}'","ff.bus_fare>0","ff.transaction_id IS NULL"]
    conditions << "ff.school_id=#{MultiSchool.current_school.id}" if defined?(MultiSchool)
    where_condition = conditions.join(" AND ")
    transport=" UNION ALL (SELECT ff.receiver_id student_id,CONCAT('t',fc.id) collection_id,fc.due_date due_date, fc.name collection_name, ff.bus_fare balance, st.batch_id batch_id FROM `transport_fees` ff INNER JOIN `transport_fee_collections` fc ON `fc`.id = `ff`.transport_fee_collection_id and ff.receiver_type='Student' INNER JOIN students st on st.id=ff.receiver_id AND ff.receiver_type='Student' WHERE (#{where_condition}))"
    transport
  end

  def sql_for_hostel
    conditions = ["`fc`.`is_deleted` = 0","fc.due_date < '#{Date.today}'","ff.rent>0","ff.finance_transaction_id IS NULL"]
    conditions << "ff.school_id=#{MultiSchool.current_school.id}" if defined?(MultiSchool)
    where_condition = conditions.join(" AND ")
    hostel=" UNION ALL (SELECT ff.student_id student_id,CONCAT('h',fc.id) collection_id, fc.due_date due_date, fc.name collection_name, ff.rent balance, st.batch_id batch_id FROM `hostel_fees` ff INNER JOIN `hostel_fee_collections` fc ON `fc`.id = `ff`.hostel_fee_collection_id INNER JOIN students st on st.id=ff.student_id WHERE (#{where_condition}))"
    hostel
  end

  def derived_sql_table
    all_available_plugins=FedenaPlugin.accessible_plugins & ["fedena_hostel","fedena_transport"]
    available_plugins= '(' + sql_for_finance
    all_available_plugins.each{|ap| available_plugins=available_plugins + send("sql_for_#{ap.gsub('fedena_', '')}")}
    available_plugins=available_plugins + ')'
    available_plugins
  end
end
