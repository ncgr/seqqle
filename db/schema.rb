# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "alpheus_hits", :force => true do |t|
    t.string  "name",   :null => false
    t.integer "ref_id", :null => false
  end

  create_table "destinations", :force => true do |t|
    t.string "tag",  :limit => 120, :null => false
    t.string "name",                :null => false
    t.string "url"
  end

  add_index "destinations", ["tag"], :name => "tag", :unique => true

  create_table "seqqle_hits", :force => true do |t|
    t.integer   "seqqle_id"
    t.string    "query"
    t.string    "hit"
    t.float     "percent"
    t.integer   "alignment_len"
    t.integer   "query_from"
    t.integer   "query_to"
    t.integer   "hit_from"
    t.integer   "hit_to"
    t.string    "e_val"
    t.integer   "bit_score"
    t.timestamp "timestamp",     :null => false
  end

  create_table "seqqle_reports", :force => true do |t|
    t.integer   "seqqle_id"
    t.integer   "sequence_category_id"
    t.string    "query"
    t.string    "species"
    t.string    "reference"
    t.string    "hit"
    t.float     "percent"
    t.integer   "alignment_len"
    t.integer   "query_from"
    t.integer   "query_to"
    t.integer   "hit_from"
    t.integer   "hit_to"
    t.string    "e_val"
    t.integer   "bit_score"
    t.text      "neighbors"
    t.integer   "ref_id"
    t.integer   "sort_order"
    t.timestamp "timestamp",            :null => false
  end

  create_table "seqqles", :force => true do |t|
    t.string    "seq_type"
    t.text      "seq"
    t.string    "seq_file"
    t.string    "seq_hash"
    t.string    "ip_address", :limit => 64
    t.timestamp "timestamp",                :null => false
  end

  create_table "sequence_categories", :force => true do |t|
    t.string "name", :null => false
  end

  create_table "target_elements", :force => true do |t|
    t.string  "tag",          :limit => 120, :null => false
    t.string  "display_name", :limit => 120, :null => false
    t.text    "description"
    t.string  "url",          :limit => 120
    t.integer "target_id",                   :null => false
  end

  add_index "target_elements", ["tag"], :name => "tag", :unique => true

  create_table "targets", :force => true do |t|
    t.string "tag",          :limit => 120, :null => false
    t.string "display_name", :limit => 120, :null => false
    t.text   "description"
    t.string "url",          :limit => 120
  end

  add_index "targets", ["tag"], :name => "tag", :unique => true

end
