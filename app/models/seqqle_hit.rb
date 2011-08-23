
class SeqqleHit < ActiveRecord::Base

  belongs_to :seqqle

  # Genomes and regex
  GENOMES = {
    "gm" => /gm[0-9]+/, 
    "mt" => /mt_3_5_1_chr[0-9]/,        # Default to mt3.5.1
    "mt3.0" => /mt_3_0_chr[0-9]/, 
    "mt3.5.1" => /mt_3_5_1_chr[0-9]/, 
    "lj" => /lj_chr[0-9]/,
    "all" => /./
  }.freeze

  #
  # Get Seqqle Hits by seqqle id.
  #
  def self.get_hits_by_seqqle_id(id, order = nil)
    order ||= "id ASC"
    find(:all, :conditions => {:seqqle_id => id}, :order => order)
  end

  #
  # Get Seqqle Hits by seqqle id and filter by params.
  #
  def self.get_hits_for_gff_by_params(id, genomes = nil, query = nil)
    return nil unless id > 0
  
    order = "bit_score DESC"

    if genomes.blank? && query.blank?
      return get_hits_by_seqqle_id(id, order)
    end
    if query.blank?
      results = find(:all, :conditions => {:seqqle_id => id}, :order => order)
    else
      conditions = ["seqqle_id = ? AND query = ?", id, query]
      results = find(:all, :conditions => conditions, :order => order)
    end
    ret = results

    # Filter by genome
    unless genomes.blank?
      arr = genomes.split(',')
      arr.each do |a|
        arr.delete(a) unless GENOMES.has_key?(a)
      end

      return [] if arr.empty?

      # Return all results. 
      return ret if arr.include?("all")

      ret = []
      for i in 0...results.length
        arr.each do |a|
          if results[i][:hit] =~ GENOMES[a]
            ret << results[i]
          end
        end
      end
    end
    ret
  end
end
