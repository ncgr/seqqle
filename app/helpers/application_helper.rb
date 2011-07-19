# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  #
  # Helper to provide a link to sort a will_paginate table header. If key is nil,
  # the method will attempt based on title.
  #
  def wp_sort(method, title, key = nil)
    if !method.kind_of?(Symbol) || title.nil?
      return nil
    end

    # Set key
    key.nil? ? key = title.downcase : key = key

    # Set the default direction param.
    params[:direction].nil? ? params[:direction] = "desc" : params[:direction]

    # Sort direction
    dir = (params[:direction].upcase == "DESC") ? "asc" : "desc"

    if params[:direction] && key == params[:sort]
      up = " <img src=/images/up_arrow.gif alt="" />"
      down = " <img src=/images/down_arrow.gif alt="" />"
      title = (dir == "desc") ? title + up : title + down
    end

    # Sort options - :page must be passed along for pagination to work properly.
    options = {:sort => key, :direction => dir, :page => params[:page], :query => params[:query]}

    link_to title, self.send(method, options)
  end

  #
  # Helper to provide a link to get data by a specific param.
  #
  def get_data_by_param(method, title, param)
    if !method.kind_of?(Symbol) || title.nil? || param.nil?
      return nil
    end
    options = {:query => param}

    link_to title, self.send(method, options)
  end

  #
  # Helper to gather sequence categories.
  #
  def get_hit_seq_categories(data = {})
    return data if data.blank?

    ret = {}
    for i in 0...data.length
      ret[i] = data[i].sequence_category.name
    end
    ret
  end

end
