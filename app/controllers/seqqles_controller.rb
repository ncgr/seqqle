
class SeqqlesController < ApplicationController

  include DataExport

  def index
    redirect_to :action => "new"
  end

  def new
    @seqqle = Seqqle.new
  end

  def create
    @seqqle = Seqqle.new(params[:seqqle])

    if !@seqqle.valid?
      respond_to do |format|
        format.html {render :action => "new"}
        format.xml {render :xml => @seqqle.errors, :status => :unprocessable_entity}
      end
      return
    end

    # File upload.
    if !@seqqle.seq_file.blank? && (File.exists? params[:seqqle][:seq_file])
      @seqqle.seq = params[:seqqle][:seq_file].read
      @seqqle.seq_file = nil
    end

    # If the user uploads data that is not valid UTF-8 (ex: Word Doc, Excel File, etc.),
    # u_unpack raises an expection.
    begin
      ActiveSupport::Multibyte::Chars.u_unpack(@seqqle.seq)
    rescue Exception => e
      puts e.message
      flash[:notice] = Seqqle::ERROR_MESSAGES[72]
      redirect_to :action => "new"
      return
    end

    # Hash for db lookup.
    seq_hash = Digest::MD5.hexdigest(@seqqle.seq)
    @seqqle.seq_hash = "#{seq_hash}-#{rand(10000000)}"

    # I have big plans for this!
    # Idea - track the ip address. If the same ip visits 10 + times, present them
    # with the option to script the form.
    @seqqle.ip_address = request.remote_ip

    if @seqqle.save
      # Execute search
      search_result = search(@seqqle.id, @seqqle.seq_hash)

      # Did blast execute successfully or return 0 hits?
      # See Seqqle::ERROR_MESSAGES for error code information.
      if search_result > 0
        # Delete the record.
        Seqqle.delete(@seqqle.id)
        flash[:notice] = Seqqle::ERROR_MESSAGES[search_result]
        redirect_to :action => "new"
        return
      end
    else
      flash[:error] = "Unable to save data."
      redirect_to :action => "new"
      return
    end
    redirect_to seqqle_path(@seqqle.seq_hash)
  end

  def show
    @seqqle = Seqqle.find_seq_hash(params[:id])
    @hits = {}

    # Paginate results?
    @paginate = BLAST_INFO['paginate_results']

    if @seqqle.nil?
      flash[:notice] = "The data you requested is unavailable. Please check your URL and try again."
      redirect_to :action => "new"
      return
    end

    # Count the number of queries submitted.
    count = SeqqleHit.count('query', :conditions => {:seqqle_id => @seqqle.id}, :distinct => true)

    ## Post Processing Block ##
    # If the user is requesting results for the first time, we need to make sure the data was
    # transfered to SeqqleReport after the pre processing.
    unless SeqqleReport.exists?(:seqqle_id => @seqqle.id)
      Seqqle.post_process_data(@seqqle.id, count)
    end

    respond_to do |format|
      format.html {
        get_hits(count)
      }
      format.xml {
        get_hits(count)
        render :xml => params[:query] ? @hits : SeqqleReport.get_descriptions(SeqqleReport.get_reports_by_seqqle_id(@seqqle.id))
      }
      format.json {
        get_hits(count)
        render :json => params[:query] ? @hits : SeqqleReport.get_descriptions(SeqqleReport.get_reports_by_seqqle_id(@seqqle.id))
      }
      format.gff {
        render :text => write_gff(SeqqleHit.get_hits_for_gff_by_params(@seqqle.id, params[:genomes], params[:query]))
      }
    end
  end

  private

  #
  # Executes blast on a given dataset based on sequence type.
  #
  def search(id, hash)
    res = 75        # Search param(s) was/were not properly set or SSH failed.

    return res if id <= 0 || hash.empty?

    # run-blast command
    cmd = "#{BLAST_INFO['script']} -i #{id} -g #{hash} -e #{RAILS_ENV} " +
      "-l #{BLAST_INFO['log_dir']} " +
      "-d #{ActiveRecord::Base.configurations[RAILS_ENV]['database']} " +
      "-k #{ActiveRecord::Base.configurations[RAILS_ENV]['host']} " +
      "-u #{ActiveRecord::Base.configurations[RAILS_ENV]['username']} " +
      "-p #{ActiveRecord::Base.configurations[RAILS_ENV]['password']} " +
      "-b #{BLAST_INFO['blast_db']} -t #{BLAST_INFO['threads']} " +
      "-c #{BLAST_INFO['blast_cmd']} -s #{BLAST_INFO['num_swissprot']}"

    # Optional args
    if BLAST_INFO['find_neighbors_threshold']
      cmd << " -f #{BLAST_INFO['find_neighbors_threshold']}"
    end

    logger.info "\n-- run-blast command --\n" + cmd + "\n\n"

    if BLAST_INFO['remote']
      # Execute the blast script on the remote machine.
      Net::SSH.start(BLAST_INFO['host'], BLAST_INFO['user']) do |ssh|
        ssh.open_channel do |ch|
          ch.exec(cmd) do |ch, success|
            unless success
              puts "Channel exec() failed. :("
            else
              # Read the exit status of the remote process.
              ch.on_request("exit-status") do |ch, data|
                res = data.read_long
              end
            end
          end
        end
        ssh.loop
      end
    else
      system(cmd)
      res = $?.exitstatus
    end
    res
  end

  #
  # Helper method to gather @hits and generate GDE and CMTV urls.
  #
  def get_hits(count)
    # Logic to choose view specific fields.
    if params[:query].blank?
      if count > 1
        # Multiple queries where entered.
        format_multi_queries
      else
        # Single query was entered.
        @hits = SeqqleReport.get_descriptions(
          SeqqleReport.find_by_params(@seqqle.id, params[:sort], params[:direction], @paginate, params[:page])
        )
      end
    else
      # View the selected query form a multi-query display.
      conditions = "AND query = '#{params[:query]}'"
      @hits = SeqqleReport.get_descriptions(
        SeqqleReport.find_by_params(@seqqle.id, params[:sort], params[:direction], @paginate, params[:page], conditions)
      )
    end
    @base_url = request.url().split('?').first

    @cmtv_all = URI.escape(@base_url + ".gff?genomes=gm,lj,mt3.5.1,cc&query=#{params[:query]}", "?=&,") # CMTV All genomes
    @cmtv_gm  = URI.escape(@base_url + ".gff?genomes=gm&query=#{params[:query]}", "?=&,")               # CMTV gm
    @cmtv_lj  = URI.escape(@base_url + ".gff?genomes=lj&query=#{params[:query]}", "?=&,")               # CMTV lj
    @cmtv_mt  = URI.escape(@base_url + ".gff?genomes=mt3.5.1&query=#{params[:query]}", "?=&,")          # CMTV mt
    @cmtv_cc  = URI.escape(@base_url + ".gff?genomes=cc&query=#{params[:query]}", "?=&,")               # CMTV cc

    # GDE Gm view
    @gm = '#'
    unless GDE['url'].nil?
      @gm = GDE['url'] + @base_url + ".gff?genomes=gm&query=#{params[:query]}"
      if Rails.env.production?
        @gm.sub!("search.comparative-legumes.org", "velarde:8020")
      end
    end
  end

  #
  # Helper method to format @hits for multiple queries.
  #
  def format_multi_queries
    @hits = SeqqleReport.get_descriptions(
      SeqqleReport.find_by_params(@seqqle.id, params[:sort], params[:direction], @paginate, params[:page])
    )

    queries, references = [], {}

    queries = @hits.uniq { |h| h[:query] }

    # Loop over the queries and store all of the query specific references.
    queries.each do |q|
      references[q[:query]] = []
      @hits.each do |h|
        references[q[:query]] << h[:reference] if h[:query] == q[:query]
      end
    end

    # Store the refs for the view.
    queries.each do |q|
      q[:refs] = references[q[:query]].uniq.sort
    end

    @hits = queries

    queries = references = nil
  end

end
