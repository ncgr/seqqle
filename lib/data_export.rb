#
# DataExport Module
#
require 'experts'

module DataExport

  #
  # Generates proper HTML header for GFF file.
  #
  def render_gff(data, filename)
    filename += '.gff' if File.extname(filename).empty?
    send_data(write_gff(data), :filename => filename, :type => "text/plain", :disposition => "attachment")
  end

  #
  # Generates proper HTML header for XML file.
  #
  def render_xml(data, filename)
    filename += '.xml' if File.extname(filename).empty?
    send_data(data.to_xml, :filename => filename, :type => "application/xml", :disposition => "attachment")
  end

  #
  # Generates proper HTML header for JSON file.
  #
  def render_json(data, filename)
    filename += '.json' if File.extname(filename).empty?
    send_data(data.to_json, :filename => filename, :type => "application/json", :disposition => "attachment")
  end

  #
  # Generate data in GFF Version 3 format.
  #
  def write_gff(data)
    return nil if data.nil?

    extend Experts::ExpertMethods

    gff = "##gff-version 3\n"
    source = "."
    type = "match"
    strand = ""
    phase = "."

    for i in 0...data.length
      start, stop = data[i].hit_from, data[i].hit_to
      start > stop ? strand = "-" : strand = "+"                          # Sets strand
      start, stop = format_start_stop(data[i].hit_from, data[i].hit_to)   # Format start and stop

      hit_info = data[i].hit.split(':')
      build = hit_info.first
      hit = hit_info.last

      eval = data[i].e_val
      query = data[i].query
      query_from = data[i].query_from
      query_to = data[i].query_to

      str =  "#{hit}\t#{source}\t#{type}\t#{start}\t#{stop}\t#{eval}\t#{strand}\t#{phase}\t" + 
             "Target=#{query} #{query_from} #{query_to};Note=Build #{build};Name=#{query}\n"
      gff << str
    end

    gff
  end

end
