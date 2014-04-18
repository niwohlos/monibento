class Hash
  alias old_method_missing method_missing

  def method_missing *args
    if args.size.eql?(1) && args.first.is_a?(Symbol) && self.has_key?(args.first)
      self[args.first]
    elsif args.size.eql?(2) && args.first.is_a?(Symbol) && args.first.to_s.end_with?("=")
      self[args.shift[0..-2].to_sym] = args.shift
    else
      old_method_missing *args
    end
  end
end