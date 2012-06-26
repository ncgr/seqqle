
class SeqqleReport < ActiveRecord::Base

  include Experts

  belongs_to :seqqle
  belongs_to :sequence_category

  # Sort db columns
  SORT_COLS = ["query", "species", "bit_score", "reference"]
  # Sort Direction
  DIRECTION = ["DESC", "ASC"]

  # Destination columns
  DESTINATION_DATA = ["url"]
  # Element columns
  ELEMENT_DATA = ["display_name"]

  # GBrowse view area constant. Set this value to nil to ignore.
  VIEWING_AREA = 50000
  # GBrowse Track Details
  TYPE = "LIS"
  NAME = "LIS_QUERY"

  #
  # Find Blast Reports based on params and return paginated results if paginate is true.
  #
  def self.find_by_params(id, sort, direction, paginate = false, page = nil, cond = "")
    # Default Order
    order = "sequence_category_id ASC, bit_score DESC"

    #Default Conditions
    conditions = "seqqle_id = #{id}"
    # Additional conditions
    conditions << " " + cond unless cond.blank?
    # Sanitize conditions
    conditions = sanitize_sql_for_conditions(conditions)

    # Try the user supplied query params or use the default.
    if SORT_COLS.include?(sort) && DIRECTION.include?(direction.upcase)
      order = "sequence_category_id ASC, #{sanitize_sql_for_conditions(sort)} #{sanitize_sql_for_conditions(direction)}"
    end

    if paginate
      return paginate(:all, :per_page => 50, :conditions => conditions, :page => page, :order => order, :include => [:sequence_category])
    end

    find(:all, :conditions => conditions, :order => order, :include => [:sequence_category])
  end

  #
  # Get Seqqle Reports by seqqle_id.
  #
  def self.get_reports_by_seqqle_id(id, order = nil)
    order ||= "bit_score DESC"
    find(:all, :conditions => {:seqqle_id => id}, :order => order)
  end

  #
  # Gathers the descriptions for a Seqqle Report.
  #
  def self.get_descriptions(data = {})
    # Loop through the data and get the "expert" descriptions, urls, etc.
    # The "expert" descriptions are NOT saved in the database.
    for i in 0...data.length
      format_description(data[i])
    end
    data
  end

  private

  #
  # Description generator filter. This method filters the results based on tag
  # and calls each "expert" method to generate an appropriate description based
  # on the database tables Destinations and TargetElements.
  #
  # To plug in another "expert," format the blast report hit to the following.
  #   ex: tag:tag_element
  # The Post Processing block transforms the blast report into the following.
  #   ex: tag_element@data source -> lj_genome_2_5@kazusa
  # For more information see the Post Processing Block in seqqle.rb.
  #
  # Add another when statement to the case in format_descritption matching tag,
  # and create another method to generate the URL.
  #
  def self.format_description(data)
    hit         = data.hit.split(':')
    tag         = hit.first
    tag_element = hit.last

    Destination.first(:conditions => {:tag => tag}, :select => DESTINATION_DATA.join(", ")).attributes.each do |key, val|
      data["destination_#{key}"] = val
    end
    TargetElement.first(:conditions => {:tag => tag_element}, :select => ELEMENT_DATA.join(", ")).attributes.each do |key, val|
      data["element_#{key}"] = val
    end

    # Split the tag_element and gather the necessary pieces.
    pieces = tag_element.split('_') # this should become a new emoticon! ('_')
    ref    = pieces.last

    # If scaffold is present in tag_element, add it to ref.
    # See TargetElement for more information.
    pieces.each do |c|
      if ["scaffold"].include?(c)
        ref = "#{c}_#{ref}"
      end
    end

    hit_from = data.hit_from.to_i
    hit_to   = data.hit_to.to_i

    # Expand the viewing interval while retaining the orientation
    if (hit_from <= hit_to)
      display_a = hit_from > VIEWING_AREA ? (hit_from - VIEWING_AREA) : 1
      display_b = hit_to + VIEWING_AREA
    else
      display_a = hit_from + VIEWING_AREA
      display_b = hit_to > VIEWING_AREA ? (hit_to - VIEWING_AREA) : 1
    end

    neighbors = data.neighbors
    query = data.query

    data[:element_url]          = nil                   # Generic url - base url for each hit report
    data[:contin_url]           = nil                   # Continuous hit - base url + neighboring hits
    data[:alpheus_url]          = nil                   # Alpheus url.
    data[:genome_build_version] = tag.split('@').first  # Build Version attribute for XML & JSON.

    # Format the appropriate url using an "expert."
    case tag
    when "lj_genome_2_5@kazusa"
      data[:element_url] = Lj.get_lj_url(ref, display_a, display_b, hit_from, hit_to, query)
      data[:contin_url]  = get_continuous_url(data[:element_url], ref, query, neighbors)
    when "gm_genome_rel_1_01@soybase"
      data[:element_url] = Gm.get_gm_url(ref, display_a, display_b, hit_from, hit_to, query)
      data[:contin_url]  = get_continuous_url(data[:element_url], ref, query, neighbors)
    when "gm_genome_rel_1_01@alpheus"
      data[:alpheus_url] = Gm.get_gm_alpheus_url(data.ref_id, hit_from, hit_to)
    when "mt_genome_3_0@jcvi"
      data[:element_url] = Mt.get_mt_jcvi_url(ref, display_a, display_b, hit_from, hit_to, query)
      data[:contin_url]  = get_continuous_url(data[:element_url], ref, query, neighbors)
    when "mt_genome_3_0@hapmap"
      data[:element_url] = Mt.get_mt_hapmap_url(ref, display_a, display_b, hit_from, hit_to, query)
      data[:contin_url]  = get_continuous_url(data[:element_url], ref, query, neighbors)
    when "mt_genome_3_5_1@medicago"
      data[:element_url] = Mt.get_mt_3_5_1_medicago_url(ref, display_a, display_b, hit_from, hit_to, query)
      data[:contin_url]  = get_continuous_url(data[:element_url], ref, query, neighbors)
    when "mt_affy_genechip_target"
      data[:element_url] = Mt.get_mt_affy_url(tag_element)
    when "swissprot_viridiplantae_201011"
      data[:element_url] = Swissprot.get_swissprot_url(ref)
    when "ca_transcripts_201006@alpheus"
      data[:alpheus_url] = Ca.get_ca_alpheus_url(data.ref_id)
    when "cc_genome_1_0@lis"
      data[:element_url] = Cc.get_cc_url(ref, display_a, display_b, hit_from, hit_to, query)
      data[:contin_url]  = get_continuous_url(data[:element_url], ref, query, neighbors)
    end
  end

  #
  # Displays neighbors as a continuous hit URL if the hits are on the same chromosome.
  #
  def self.get_continuous_url(url, ref, query, neighbors)
    return nil if url.nil? || ref.nil? || query.nil? || neighbors.empty?

    # See find_neighbors for array format.
    hits = neighbors.split(',')
    hsh  = {}
    add  = ""

    i = 0
    until i >= hits.length
      if hits[i + 2] == query
        # Append the neighbors to the end of the URL if the queries are identical.
        add << ",#{hits[i]}..#{hits[i + 1]}"
      else
        # Store them for later.
        hsh[hits[i + 2]] = "#{hsh[hits[i + 2]]},#{hits[i]},#{hits[i + 1]}"
      end
      i += 3      # group of 3 elements in neighbors array
    end

    url = "#{url}#{add}"

    # Do some magic to add the query + hits to the end of the parent URL.
    #
    # The hits should follow the format below.
    #   ex: add={refernece}+LIS Custom Query {query}+{starting hit}..{ending hit}
    # If the query is the same, add the next two hits to the string above.
    #   ex: add=blah blah,{next start}..{next end},{next start}..{next end}, etc.
    # If the queries don't match, start over again from add={reference}.
    #
    # For more information, visit http://gmod.org/wiki/GBrowse_Configuration/URL_schema
    unless hsh.empty?
      keys = hsh.keys
      keys.uniq!  # We only want the unique keys.

      for i in 0...keys.length
        str = "add=#{ref}+#{TYPE}+#{NAME}_#{keys[i]}+"

        hsh.each do |key, val|
          if key == keys[i]
            nums = ""
            # Remove leading comma.
            val = val.slice(1, val.length)
            val = val.split(',')

            # Append all of the vals to the string.
            j = 0
            until j >= val.length
              nums << ",#{val[j]}..#{val[j + 1]}"
              j += 2
            end

            # Remove leading comma and append to str.
            nums = nums.slice(1, nums.length)
            str = "#{str}#{nums}"
          end
        end
        url = "#{url};#{str}"
      end
    end
    url
  end

end
