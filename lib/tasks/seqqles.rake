#
# Application Rake Tasks
# 
namespace :db_cleaning do
  desc "Delete week old seqqles, seqqle hits and seqqle reports in the database."
  task :delete_seqqles => :environment do
    # Today
    t = Time.now.to_a
    today = Time.mktime(t[5], t[4], t[3]).to_i

    @seqqles = Seqqle.all
    num = 0

    @seqqles.each do |seqqle|
      # One week old records.
      d = seqqle.timestamp.to_a
      date = Time.mktime(d[5], d[4], d[3]).to_i
      date += (86400 * 7)

      if today > date
        Seqqle.destroy(seqqle.id)
        num += 1
      end
    end
    puts "#{Time.now}: Deleted #{num} seqqle(s) in the database."
  end
end
