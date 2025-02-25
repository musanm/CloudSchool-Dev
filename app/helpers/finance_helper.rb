module FinanceHelper
  # include ActionView
  # include Helpers
  # include TagHelper

def transaction_date_field
 "<div class='label-field-pair3' style='height: auto; margin-top:-17px;'>
  <label>#{t('payment_date') }</label>
                <div class='date-input-bg'>
#{calendar_date_select_tag 'transaction_date', I18n.l(Date.today,:format=>:default),:popup=>'force',:class=>'start_date'}
</div>

  </div>".html_safe
end

end

