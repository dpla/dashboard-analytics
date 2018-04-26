module DateSetter
  extend ActiveSupport::Concern

  def min_date
    Date.new(2018, 01)
  end

  def max_date
    Date.today.last_month.end_of_month
  end

  def start_date(params)
    begin
      # will raise exception if params are missing or invalid
      starting = Date.new(params[:year].to_i, params[:month].to_i)
      raise ArgumentError if starting < min_date
      starting
    rescue
      Date.today.last_month.beginning_of_month
    end
  end

  def end_date(params)
    begin
      # will raise exception if params are missing or invalid
      ending = Date.new(params[:year].to_i, params[:month].to_i)
      raise ArugumentError if ending > max_date
      ending
    rescue
      Date.today.last_month.end_of_month
    end
  end
end
