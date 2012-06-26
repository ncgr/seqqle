
class FileDownloadsController < ApplicationController

  include DataExport

  #
  # Send user requested data via simple Ajax form.
  #
  def index
    # Render Ajax form if params are nil.
    if params[:file_download].nil?
      @file_download = FileDownload.new
      session[:id] = params[:id]
      session[:filename] = params[:filename]
      params[:id] = params[:filename] = nil
      render "index.html.erb", :layout => false
      # Send data
    else
      id = session[:id]
      filename = session[:filename]
      case params[:file_download][:opts]
      when "gff"
        data = SeqqleHit.get_hits_by_seqqle_id(id, "bit_score DESC")
        render_gff(data, filename)
      when "xml"
        data = SeqqleReport.get_descriptions(SeqqleReport.get_reports_by_seqqle_id(id))
        render_xml(data, filename)
      when "json"
        data = SeqqleReport.get_descriptions(SeqqleReport.get_reports_by_seqqle_id(id))
        render_json(data, filename)
      end
    end
  end

end
