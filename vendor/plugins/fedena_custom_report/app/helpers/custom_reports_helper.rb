# To change this template, choose Tools | Templates
# and open the template in the editor.

module CustomReportsHelper 
  def t(str)
     super(str,:default=>str.to_s.titleize)
  end
end
