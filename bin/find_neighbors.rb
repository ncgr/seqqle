#!/usr/bin/env ruby
#
# Find Neighbors 
#
# Author: Ken Seal - NCGR
#

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib/')

require 'cpu_info'

class FindNeighbors

  # Genome regex
  GENOMES = [
    /gm[0-9]+/, 
    /mt_3_0_chr[0-9]/, 
    /mt_3_5_1_chr[0-9]/, 
    /lj_chr[0-9]/
  ]

  def initialize(args)
    @file      = args[0]
    @threshold = args[1]
    @cpu_info  = System::CpuInfo.new

    # Default to 10,000
    @threshold ||= 10000

    @threshold = @threshold.to_i

    exit 1 if @file.nil?
    exit 1 unless File.file?(@file) && File.readable?(@file)
    exit 1 unless @threshold.kind_of? Integer

    @data = File.readlines(@file)

    # @data indecies
    @query    = 0
    @hit      = 1
    @hit_from = 8 
    @hit_to   = 9

    parse_data
  end

  #
  # Parse the array of arrays to find the range of indecies for 
  # Array#values_at.
  #
  def parse_data
    hit        = nil
    values     = []
    @values_at = []
    for i in 0...@data.length
      @data[i].chomp!
      line = @data[i].split('	')
      if is_hit_to_genome?(line[1].split(':').last)
        if line[1].split(':').last != hit
          hit = line[1].split(':').last
          values << i
          if values.length % 2 == 0
            @values_at << "#{values[0]}...#{values[1]}"
            values = []
            values << i
          end
        end
      else
        line << "\t"
      end
    end
    execute_find_neighbors
    write_results_to_file
  end

  #
  # Helper to check if the hit is to a genome.
  #
  def is_hit_to_genome?(hit)
    GENOMES.each do |g|
      return true if hit =~ g
    end
    false
  end

  #
  # Helper to execute find_neighbors.
  #
  def execute_find_neighbors
    # Gather some system info
    num_cpus    = @cpu_info.num_processors
    free_cpus   = @cpu_info.num_free_processors
    limit       = num_cpus / 2

    limit = free_cpus if free_cpus < limit

    num_cmds = @values_at.length

    # To use recursion or not to use recursion?
    if num_cmds > limit
      spawn_threads_in_batch(0, limit, @values_at)		
    else
      spawn_threads(@values_at)
    end
  end

  #
  # Recursively spawn threads one batch at a time.
  #
  def spawn_threads_in_batch(start, limit, arr)
    values = arr.values_at(start...limit)
    return if values.empty?
    spawn_threads(values)
    spawn_threads_in_batch(limit, limit + limit, arr)
  end

  #
  # Spawn threads.
  #
  def spawn_threads(arr)
    threads = []
    arr.each do |c|
      # Execute find_neighbors on the original array of arrays 
      # using Array#vlaues_at. 
      threads << Thread.new {find_neighbors(@data.values_at(eval(c)))}
    end
    # Wait for every Thread to finish working.
    threads.each {|t| t.join}
  end

  #
  # Method to find blast hit neighbors (transitive closure) on the same chromosome. 
  #
  # This method checks to see if two hit_from / hit_to pairs completely overlap, partially overlap 
  # or if the ends of each hit pair are within threshold of one another. If so, store the data to 
  # present it to the user as a multi-hit link to gbrowse.
  #
  def find_neighbors(data)

    if data.length == 1
      return data[0] << "\t"
    end

    copy = data.clone

    # Loop over datasets to find neighbors if they share the same tag (chromosome).
    # Note: the datasets are identical (copy = data) so we call next if i == k. 
    for i in 0...copy.length
      cline       = copy[i].split('	')
      copy_tag    = cline[@hit].split(':').last
      copy_first  = cline[@hit_from].to_i
      copy_last   = cline[@hit_to].to_i

      neighbors = []

      for k in 0...data.length
        next if i == k

        dline     = data[k].split('	')
        data_tag  = dline[@hit].split(':').last

        if copy_tag == data_tag
          data_first = dline[@hit_from].to_i
          data_last  = dline[@hit_to].to_i
          query      = dline[@query]

          # Check for complete overlap of the sequences.
          if data_first.between?(copy_first, copy_last) && data_last.between?(copy_first, copy_last)
            neighbors << data_first << data_last << query
            next
          elsif copy_first.between?(data_first, data_last) && copy_last.between?(data_first, data_last)
            neighbors << data_first << data_last << query
            next
          # Check for partial overlap of the sequences.
          elsif data_first.between?(copy_first, copy_last) || data_last.between?(copy_first, copy_last)
            neighbors << data_first << data_last << query
            next
          elsif copy_first.between?(data_first, data_last) || copy_last.between?(data_first, data_last)
            neighbors << data_first << data_last << query
            next
          else
          # Check to see if the ends are within threshold of each other if all else fails.
            nums = []
            nums << (copy_last - data_first) 
            nums << (data_last - copy_first)

            # Valid negative numbers generated here should be caught in the overlap checks above. 
            # Otherwise, they can report false positives (ex: (-threshold - 1)). 
            nums.delete_if {|n| n < 0}

            min = nums.min
            if !min.nil? && min < @threshold
              neighbors << data_first << data_last << query
            end
          end
        end
      end
      unless neighbors.empty?
        neighbors = neighbors.join(",")
      else
        neighbors = ""
      end
      # Add the neighbors.
      data[i] << "\t" << neighbors
    end
  end 

  #
  # Write results to file.
  #
  def write_results_to_file
    file = @file.gsub(/\.\w+/, '.fn')
    File.open(file, "w+") do |f|
      @data.each { |d| f << d + "\n" }
    end
  end

end

if __FILE__ == $0
  FindNeighbors.new(ARGV)
  exit 0
end

