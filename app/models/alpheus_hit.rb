
class AlpheusHit < ActiveRecord::Base

  #
  # Find ref_id by name and return id
  #
  def self.get_ref_id(data)
    return nil if data.blank?

    info = find(:first, :conditions => {:name => data})

    if info.blank?
      return nil
    else
      info.ref_id 
    end
  end
end
