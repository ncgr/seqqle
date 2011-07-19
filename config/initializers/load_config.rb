# Load Blast Settings
BLAST_INFO = YAML.load_file("#{RAILS_ROOT}/config/blast_settings.yml")[RAILS_ENV]

# gsub %{RAILS_ROOT}
BLAST_INFO['script'].gsub!('%{RAILS_ROOT}', RAILS_ROOT)
BLAST_INFO['log_dir'].gsub!('%{RAILS_ROOT}', RAILS_ROOT)

# Load GDE Settings
if File.exists?("#{RAILS_ROOT}/config/gde_settings.yml")
  GDE = YAML.load_file("#{RAILS_ROOT}/config/gde_settings.yml")[RAILS_ENV]
end
