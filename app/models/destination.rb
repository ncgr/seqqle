
class Destination < ActiveRecord::Base

  #
  # Find Destination tag by name and return name.
  #
  def self.get_name(tag)
    tag = tag.split(':').first
    data = find(:first, :conditions => {:tag => tag})
    data.name
  end

end
