# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_seqqle_session',
  :secret      => '034ac300137b695aa534453d7fa3d7c1b264ba1fb4d4f0119a3530b15c9ffa3ab42c1848b03cc7c0d7c40816b3d463ff60169bb8a8b1fa622ccfe592915df1ea'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
