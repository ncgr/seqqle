
class Seqqle < ActiveRecord::Base

  include Experts
  include Utilities

  has_many :seqqle_hits, :dependent => :destroy
  has_many :seqqle_reports, :dependent => :destroy

  validates_length_of :seq, 
    :minimum => 20,
    :allow_blank => true
  validates_format_of :seq_type, 
    :with => /[a-z_]+/,
    :message => " - Please select a valid sequence type.",
    :allow_blank => false
  validates_length_of :seq_file, 
    :minimum => 3, 
    :allow_blank => true

  # Run-blast and seqqle error code messages. 
  # See bin/run-blast for numeric error codes.
  ERROR_MESSAGES = {
    65 => "Your search returned error code 65.", 
    66 => "Your search returned error code 66.", 
    67 => "Your search returned error code 67.",
    68 => "Your search returned 0 hits.",
    69 => "Your search returned error code 69.",
    70 => "Your search returned error code 70.",
    71 => "Unknown sequence format. Please use FASTA.",
    72 => "Please enter your sequence(s) in Plain Text as FASTA.",
    73 => "Your search returned error code 73.",
    75 => "Your search returned error code 75."
  }.freeze

  # tmp directory to store blast sequences
  DIR = "#{RAILS_ROOT}/tmp/blast_seqs/"

  # Blast db species. If another species is added to the
  # blast target db, update it here.
  SPECIES = {
    "mt" => "Medicago truncatula", 
    "lj" => "Lotus japonicus", 
    "gm" => "Glycine max",
    "ca" => "Cicer arietinum",
    "sw" => "Viridiplantae"         # sw is for swissprot not a species.
  }.freeze

  # Find neighbors threshold
  THRESHOLD = 10000

  #
  # Find Blasts by sequence hash.
  #
  def self.find_seq_hash(hash)
    # Sanitize the supplied URL for db loookup.
    find(:first, :conditions => ["seq_hash = ?", hash])
  end

  #
  # Post processing of seqqle data.
  #
  def self.post_process_data(id, count)
    # Report object to store post processed results.
    report = SeqqleReport.new

    # Raw data.
    data = SeqqleHit.get_hits_by_seqqle_id(id, "query, bit_score DESC")

    # Find neighboring hits on the chromosome.
    find_neighbors(data, THRESHOLD)

    order = 1
    query = data[0][:query]

    for i in 0...data.length
      tag = data[i][:hit].split(':').first

      # Default sort order value.
      data[i][:sort_order] = nil

      # Add the species.
      data[i][:species] = SPECIES[tag.slice(0, 2)]

      # Add the alpheus ref_id.
      data[i][:ref_id] = AlpheusHit.get_ref_id(data[i][:hit])

      res = {}

      # Pass the pre processed data off to the experts. Each experts clones the data set and
      # returns the cloned data as well as any additional information.
      # See lib/experts.rb for more information.
      case tag
      when "mt_genome_3_0"
        res = Mt.process_mt_data(data[i])
      when "mt_genome_3_5_1"
        res = Mt.process_mt_3_5_1_data(data[i])
      when "gm_genome_rel_1_01"
        res = Gm.process_gm_data(data[i])
      when "lj_genome_2_5"
        res = Lj.process_lj_data(data[i])
      when "mt_affy_genechip_target"
        res = Mt.process_gea_data(data[i])
      when "swissprot_viridiplantae_201011"
        res = Swissprot.process_swissprot_data(data[i])
      when "ca_transcripts_201006"
        res = Ca.process_ca_data(data[i])
      end

      for k in 0...res.length
        res[k].attributes.each do |key, val|
          next if key == "id"
          report[key] = val
        end

        # Populates the sort order of each hit by query. 
        # Sort order ranks each hit by bit sore asc.
        if count > 1
          if query == data[i][:query]
            report[:sort_order] = order
          else
            query = data[i][:query]
            order = 1
            report[:sort_order] = order
          end
          order += 1
        end
        report.save
        report = SeqqleReport.new
      end
    end
  end
  
  private

  #
  # Added validation to make sure the user doesn't try to enter both seq and seq_file,
  # or leave them both blank. If that passes validation, check the byte size of the 
  # uploaded data.
  #
  def validate
    if seq.blank? && seq_file.blank?
      errors.add(:blank_fields, "- Please insert your sequence(s) in the text area or upload a file to continue.")
      return
    elsif !seq.blank? && !seq_file.blank?
      errors.add(:too_many_fields, "- Looks like you tried to upload sequence(s) in a file and in the text area.
        Please remove one to continue.")
      return
    end

    # If at least one field is set, check the size of the File or String in bytes.
    if !validate_seq_size(seq, seq_file)
      errors.add(:sequence_size_too_large, "- Your sequence(s) exceed the size limit of 50KB.")
    end
  end

  #
  # Validates size of the user's sequence(s) against max. 
  # Max defaults to 50KB.
  #
  def validate_seq_size(str, file, max = nil)
    begin
      if (!str.blank?) && (!str.kind_of? String)
        raise ArgumentError, 'validate_seq_size expects str to be a String.' 
      end
      if (!file.blank?) && (!File.exists? file)
        raise ArgumentError, 'validate_seq_size expects file to be a File.' 
      end
    rescue Exception => e
      puts e.message
      puts e.inspect
      puts "backtrace:\n" + e.backtrace.join("\n")
      return false
    end

    max ||= 50000
    size = nil

    if !file.nil?
      size = File.size(file)
    elsif !str.nil?
      size = str.bytesize
    end

    return true if size < max

    return false
  end

end
