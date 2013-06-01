class MassObject
  def self.set_attrs(*attributes)
  	@attributes = []
  	attributes.each do |attr|
  		attr_accessor attr
  		@attributes << attr
  	end
  end

  def self.attributes
  	@attributes
  end

  def self.parse_all(results)
  	results.map {|row| new(row)}
  end

  def initialize(params = {})
  	p params
  	params.each do |attr_name, value|
  		attr_name = attr_name.to_sym if attr_name.is_a?(String)
  		if self.class.attributes.include?(attr_name)
  			send("#{attr_name}=", value)
  		else
  			raise "mass assignment to unregistered attribute #{attr_name}"
  		end
  	end
  end
end
