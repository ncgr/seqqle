#
# Utilities Module
#
module Utilities

  #
  # Extend UtilityMethods
  #
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    #
    # Method to find blast hit report neighbors (transitive closure) on the same chromosome. 
    #
    # This method checks to see if two hit_from / hit_to pairs completely overlap, partially overlap 
    # or if the ends of each hit pair are within threshold of one another. If so, store the data to 
    # present it to the user as a multi-hit link to gbrowse.
    #
    def find_neighbors(data, threshold = nil)
      threshold ||= 10000
      begin
        if data.empty? || !data.kind_of?(Array)
          raise ArgumentError, "find_neighbors expects data to be an array. Neighbors will be ignored."
        elsif !threshold.kind_of?(Numeric)
          raise ArgumentError, "find_neighbors expects threshold to be Numeric. Neighbors will be ignored."
        elsif !threshold.kind_of?(Integer)
          puts "threshold converted to integer."
          puts "original: #{threshold}"
          puts "integer:  #{threshold.to_i}"
          threshold = threshold.to_i
        end
      rescue Exception => e
        puts e.message
        puts e.inspect
        puts "backtrace:\n" + e.backtrace.join("\n")
        return data
      end

      ret = {}
      hsh = data.clone

      # Loop over datasets to find neighbors if they share the same tag.
      # Note: the datasets are identical (hsh = data) so we want to skip the
      # hash if i == k. 
      for i in 0...hsh.length
        hsh_tag = hsh[i][:hit].split(':').last
        hsh_first = hsh[i][:hit_from].to_i
        hsh_last = hsh[i][:hit_to].to_i

        ret[:neighbors] = []

        for k in 0...data.length
          next if i == k
          data_tag = data[k][:hit].split(':').last

          if hsh_tag == data_tag
            data_first = data[k][:hit_from].to_i
            data_last = data[k][:hit_to].to_i
            query = data[k][:query]

            # Check for complete overlap of the sequences.
            if data_first.between?(hsh_first, hsh_last) && data_last.between?(hsh_first, hsh_last)
              ret[:neighbors] << data_first << data_last << query
              next
            elsif hsh_first.between?(data_first, data_last) && hsh_last.between?(data_first, data_last)
              ret[:neighbors] << data_first << data_last << query
              next
              # Check for partial overlap of the sequences.
            elsif data_first.between?(hsh_first, hsh_last) || data_last.between?(hsh_first, hsh_last)
              ret[:neighbors] << data_first << data_last << query
              next
            elsif hsh_first.between?(data_first, data_last) || hsh_last.between?(data_first, data_last)
              ret[:neighbors] << data_first << data_last << query
              next
            else
              # Check to see if the ends are within threshold of each other if all else fails.
              nums = []
              nums << (hsh_last - data_first) 
              nums << (data_last - hsh_first)

              # Valid negative numbers generated here should be caught in the overlap checks above. 
              # Otherwise, they can report false positives (ex: (-threshold - 1) could report a false positive). 
              nums.delete_if {|n| n < 0}

              min = nums.min
              if !min.nil? && min < threshold
                ret[:neighbors] << data_first << data_last << query
              end
            end
          end
        end
        unless ret[:neighbors].empty?
          ret[:neighbors] = ret[:neighbors].join(",")
        else
          ret[:neighbors] = nil
        end
        # Add the neighbors.
        data[i][:neighbors] = ret[:neighbors]

        # Reset ret so we don't carry over data.
        ret = {}
      end
      return
    end 

  end

end
