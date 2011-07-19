
class SequenceCategory < ActiveRecord::Base

  has_many :seqqle_reports

  def self.find_by_name(name)
    find(:first, :conditions => ["name = ?", name]).id
  end

end
