module System
  #
  # CpuInfo
  #
  # Determine processor information on Linux boxes.
  #
  # Author: Ken Seal - NCGR
  #
  class CpuInfo

    def initialize
      box = `uname`
      unless box.strip.chomp.downcase == "linux"
        raise RuntimeError, "System::CpuInfo must be executed on a Linux machine"
      end
    end

    #
    # Number of processors in use based on /proc/PID/stat values
    # state(2) and processor(38). Man proc for more information.
    #
    def processors_in_use
      procs = []
      Dir.glob("/proc/*/stat") do |filename|
        next if File.directory?(filename)
        this_proc = []
        File.open(filename) {|file| this_proc = file.gets.split.values_at(2,38)}
        procs << this_proc[1].to_i if this_proc[0] == "R"
      end
      procs.uniq.length
    end

    #
    # Number of processors.
    #
    def num_processors
      File.readlines("/proc/cpuinfo").delete_if {|l| l.index("processor") == nil}.length
    end

    #
    # Number of cores.
    #
    def num_cores
      cpuinfo = File.readlines("/proc/cpuinfo").delete_if {|l| l.index("cpu cores") == nil}
      cores = []
      cpuinfo.each do |c|
        cores << c.split(':').last.strip.chomp.to_i
      end
      cores.inject(0) {|s,v| s + v}
    end

    #
    # Number of free processors.
    #
    def num_free_processors
      num_processors - processors_in_use
    end

  end
end
