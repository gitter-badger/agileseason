class Graphs::DurationController < ApplicationController
  before_action :fetch_board

  def index
    @chart_series_data = fetch_chart_duration_data
    @forecast_duration = DurationService.new(@board).forecast
  end

  private

  def fetch_chart_duration_data
    group_durations = DurationService.new(@board).fetch_group
    normolize_chart_serias(group_durations)
  end

  def normolize_chart_serias(group_durations)
    max = group_durations.try(:last).try(:first).to_i
    normolized = (1..max).each_with_object({}) { |day, hash| hash[day] = 0 }
    group_durations.each do |pair|
      normolized[pair.first] = pair.second
    end
    normolized.sort
  end
end