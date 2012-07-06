#
# Experts Module
#
# Purpose:  Experts Module contains expert classes to process data for specific genomes.
#
module Experts

  SEQUENCE_CATEGORIES = {
    :gc => "Genomic Context",
    :ex => "Expression",
    :rf => "Role and Function"
  }.freeze

  #
  # Expert Methods
  #
  module ExpertMethods

    #
    # Processes data set and appends tags and seq_categories. Reference is
    # generated via the destinations table in the db.
    #
    def process_data(data, tags = [], seq_category = [])
      return data if data.blank? || tags.blank? || seq_category.blank?

      ret = {}

      data.id = nil
      for i in 0...tags.length
        ret[i]                        = data.clone
        ret[i][:hit]                  = tags[i]
        ret[i][:reference]            = Destination.get_name(tags[i])
        ret[i][:sequence_category_id] = SequenceCategory.find_by_name(seq_category[i])
      end

      ret
    end

    #
    # Format and return ref for URL. Some gbrowse instances require leading zeros while
    # others do not.
    # Ex: ref=chr08 vs ref=chr8
    #
    def format_ref(ref, type)
      len = ref.length
      case type
      when "soybase"
        if len < 4
          chr = ref.slice(2, len)
          return "gm0#{chr}"
        end
      when "jcvi"
        if len < 5
          chr = ref.slice(3, len)
          return "chr0#{chr}"
        end
      when "medicago"
        if ref =~ /chr[0-9]/
          return "Mt#{ref.slice(/[0-9]/)}"
        else
          return ref
        end
      when "hapmap"
        return ref.gsub(/0/, '')
      when "cajca"
        if ref =~ /CcLG[0-9]+/
          return "Cc#{ref.slice(/[0-9]+/)}"
        else
          return ref
        end
      end
      ref
    end

    #
    # Reverse start and stop if necessary. Certain gbrowse instances do not
    # render properly if start > stop.
    #
    def format_start_stop(start, stop)
      tmp_start = start
      tmp_stop = stop

      if start > stop
        tmp_start, tmp_stop = stop, start
      end
      return tmp_start, tmp_stop
    end
  end

  #
  # Medicago truncatula
  #
  class Mt

    extend ExpertMethods

    #
    # Process the blast hit data for Mt. Add each unique site to link out to in the tags array.
    # Note: seq_cat array index corresponds to the index of tag.
    #
    def self.process_mt_data(data)
      return data if data.blank?

      hits = data[:hit].split(':')
      tags = ["#{hits[0]}@hapmap:#{hits[1]}", "#{hits[0]}@jcvi:#{hits[1]}"]
      seq_cat = [SEQUENCE_CATEGORIES[:gc], SEQUENCE_CATEGORIES[:gc]]

      process_data(data, tags, seq_cat)
    end

    #
    # Process the blast hit data for Mt. Add each unique site to link out to in the tags array.
    # Note: seq_cat array index corresponds to the index of tag.
    #
    def self.process_mt_3_5_1_data(data)
      return data if data.blank?

      hits = data[:hit].split(':')
      tags = ["#{hits[0]}@medicago:#{hits[1]}"]
      seq_cat = [SEQUENCE_CATEGORIES[:gc]]

      process_data(data, tags, seq_cat)
    end

    #
    # Process the blast hit data for Mt Gene Expression Atlas data. Add each unique site to
    # link out to in the tags array.
    # Note: seq_cat array index corresponds to the index of tag.
    #
    def self.process_gea_data(data)
      return data if data.blank?

      hits = data[:hit].split(':')
      tags = ["#{hits[0]}:#{hits[1]}"]
      seq_cat = [SEQUENCE_CATEGORIES[:ex]]

      process_data(data, tags, seq_cat)
    end

    #
    # Format url for Medicago truncatula JCVI.
    #
    def self.get_mt_jcvi_url(ref, display_a, display_b, hit_from, hit_to, query)
      ref = format_ref(ref, "jcvi")
      url = "http://gbrowse.jcvi.org/cgi-bin/gbrowse/medicago/?ref=#{ref};start=#{display_a};" +
            "stop=#{display_b};width=1024;version=100;cache=on;drag_and_drop=on;show_tooltips=on;grid=on;" +
            "label=Gene-Transcripts_all-Transcripts_Bud-Transcripts_Blade-Transcripts_Root-Transcripts_Flower" +
            "-Transcripts_Seed-Transcripts_mtg-Gene_Models-mt_fgenesh-genemarkHMM-genscan-fgenesh-TC_poplar" +
            "-TC_maize-TC_arabidopsis-TC_Lotus-TC_soybean-TC_cotton-TC_medicago-TC_rice-TC_sorghum;" +
            "add=#{ref}+LIS+LIS_Query_#{query}+#{hit_to}..#{hit_from}"
    end

    #
    # Format url for Medicago truncatula build 3.5.1.
    #
    def self.get_mt_3_5_1_medicago_url(ref, display_a, display_b, hit_from, hit_to, query)
      ref = format_ref(ref, "medicago")

      # gbrowse instance will not display our custom LIS Query track if start > stop.
      start, stop = format_start_stop(display_a, display_b)

      url = "http://medtr.comparative-legumes.org/gb2/gbrowse/3.5.1/?ref=#{ref};start=#{start};" +
            "stop=#{stop};width=1024;version=100;flip=0;grid=1;" +
            "add=#{ref}+LIS+LIS_Query_#{query}+#{hit_to}..#{hit_from}"
    end

    #
    # Format url for Medicago truncatula HapMap.
    #
    def self.get_mt_hapmap_url(ref, display_a, display_b, hit_from, hit_to, query)
      ref = format_ref(ref, "hapmap")
      url = "http://www.medicagohapmap.org/cgi-bin/gbrowse/mthapmap/?q=#{ref}:#{display_a}..#{display_b};" +
            "t=Genes+Transcript+ReadingFrame+Translation+SNP+SNP_HM005+CovU_HM005+SNP_HM006+CovU_HM006+SNP_HM029+CovU_HM029;" +
            "c=1;add=#{ref}+LIS+LIS_Query_#{query}+#{hit_to}..#{hit_from}"
    end

    #
    # Format url for Medicago truncatula gene expression atlas.
    #
    def self.get_mt_affy_url(ref)
      url = "http://bioinfo.noble.org/gene-atlas/v2/probeset.php?id=#{ref}&submit=Go"
    end
  end

  #
  # Glycine max
  #
  class Gm

    extend ExpertMethods

    #
    # Process the blast hit data for Gm. Add each unique site to link out to in the tags array.
    # Note: seq_cat array index corresponds to the index of tag.
    #
    def self.process_gm_data(data)
      return data if data.blank?

      hits = data[:hit].split(':')
      tags = ["#{hits[0]}@soybase:#{hits[1]}"]
      seq_cat = [SEQUENCE_CATEGORIES[:gc]]

      process_data(data, tags, seq_cat)
    end

    #
    # Format url for Glycine max.
    #
    def self.get_gm_url(ref, display_a, display_b, hit_from, hit_to, query)
      ref = format_ref(ref, "soybase")
      url = "http://soybase.org/gbrowse/cgi-bin/gbrowse/gmax1.01/?ref=#{ref};start=#{display_a};stop=#{display_b};" +
            "version=100;cache=on;drag_and_drop=on;show_tooltips=on;grid=on;" +
            "add=#{ref}+LIS+LIS_Query_#{query}+#{hit_to}..#{hit_from}"
    end

  end

  #
  # Lotus japonicus
  #
  class Lj

    extend ExpertMethods

    #
    # Process the blast hit data for Lj. Add each unique site to link out to in the tags array.
    # Note: seq_cat array index corresponds to the index of tag.
    #
    def self.process_lj_data(data)
      return data if data.blank?

      hits = data[:hit].split(':')
      tags = ["#{hits[0]}@kazusa:#{hits[1]}"]
      seq_cat = [SEQUENCE_CATEGORIES[:gc]]

      process_data(data, tags, seq_cat)
    end

    #
    # Format url for Lotus japonicus.
    #
    def self.get_lj_url(ref, display_a, display_b, hit_from, hit_to, query)
      # Lotus j. gbrowse instance will not display our custom LIS Query track if start > stop.
      start, stop = format_start_stop(display_a, display_b)

      url = "http://gsv.kazusa.or.jp/cgi-bin/gbrowse/lotus/?ref=#{ref};start=#{start};stop=#{stop};" +
            "width=1024;version=100;label=contig-phase3-phase1%%2C2-annotation-GMhmm-GenScan-blastn-tigrgi-blastx-marker;" +
            "grid=on;add=#{ref}+LIS+LIS_Query_#{query}+#{hit_from}..#{hit_to}"
    end
  end

  #
  # Swiss Protein
  #
  class Swissprot

    extend ExpertMethods

    #
    # Process the blast hit data for Swiss Protein Data Bank. Add each unique site to
    # link out to in the tags array.
    # Note: seq_cat array index corresponds to the index of tag.
    #
    def self.process_swissprot_data(data)
      return data if data.blank?

      hits = data[:hit].split(':')
      tags = ["#{hits[0]}:#{hits[1]}"]
      seq_cat = [SEQUENCE_CATEGORIES[:rf]]

      process_data(data, tags, seq_cat)
    end

    #
    # Format url for Swiss Protein Data Bank.
    #
    def self.get_swissprot_url(ref)
      url = "http://www.uniprot.org/uniprot/#{ref}"
    end
  end

  #
  # Cajanus cajan
  #
  class Cc

    extend ExpertMethods

    #
    # Process the blast hit data for Cc. Add each unique site to link out to in the tags array.
    # Note: seq_cat array index corresponds to the index of tag.
    #
    def self.process_cc_data(data)
      return data if data.blank?

      hits = data[:hit].split(':')
      tags = ["#{hits[0]}@lis:#{hits[1]}"]
      seq_cat = [SEQUENCE_CATEGORIES[:gc]]

      process_data(data, tags, seq_cat)
    end

    #
    # Format url for Cajanus cajan build 1.0.
    #
    def self.get_cc_url(ref, display_a, display_b, hit_from, hit_to, query)
      ref = format_ref(ref, "cajca")

      # gbrowse instance will not display our custom LIS Query track if start > stop.
      start, stop = format_start_stop(display_a, display_b)

      url = "http://cajca.comparative-legumes.org/gb2/gbrowse/1.0/?ref=#{ref};start=#{start};" +
            "stop=#{stop};width=1024;version=100;flip=0;grid=1;" +
            "add=#{ref}+LIS+LIS_Query_#{query}+#{hit_to}..#{hit_from}"
    end

  end

end
