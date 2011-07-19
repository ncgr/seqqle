#
# FileDownload Model
#
# Does NOT have a database table hence lack of ActiveRecord::Base inheritance.
# This model exists to pass around :opts via Ajax request.
#
class FileDownload
  attr_accessor :opts, :id
end
