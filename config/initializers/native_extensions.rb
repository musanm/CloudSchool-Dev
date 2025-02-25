Array.send :include,WillPaginateExtension::Array
Hash.send :include,WillPaginateExtension::Hash
Paperclip::Interpolations.send :include,PaperclipCustomInterpolation
Hash.instance_eval do
  def from_xml(*args)
    super(*args).with_indifferent_access
  end
end

Array.class_eval do
 def shuffle_it(seed = nil)
   srand(seed) if seed
   self.sort{|a, b| Kernel.rand <=> Kernel.rand }
 end
end