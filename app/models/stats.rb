class Stats
  include ActiveModel::Serializers::JSON
  attr_reader :mode, :events, :turns

  def attributes
    instance_values
  end

  def as_json(opts = nil)
    super(
      only:[:mode],
      methods:[
        :active_driver_count, :average_drive_time, :maximum_drive_time,
        :minimum_drive_time, :current_driver_id, :current_drive_time,
        :last_driver_id, :last_drive_time, :total_drive_time
      ]
    )
  end

  def initialize(events, turns, mode = :both)
    @events = events.sort{|e1, e2| e1[2] <=> e2[2]}
    @turns = turns
    @mode = mode.to_sym
  end

  def active_driver_count
    @turns.map(&:second).uniq.size
  end

  def average_drive_time
    c = active_driver_count
    return if c.nil?
    return 0.0 if c == 0
    total_drive_time.to_f / c
  end

  def maximum_drive_time
    @turns.map(&:third).max
  end

  def minimum_drive_time
    @turns.map(&:third).min
  end

  def current_driver_id
    case @mode
    when :both then
      e = @events.reverse_each.find{|e| e[3] == 'arriving'}
      e[1] if e.present?
    when :leaving then nil
    end
  end

  def current_drive_time
    case @mode
    when :both then
      e = @events.reverse_each.find{|e| e[3] == 'arriving'}
      Time.zone.now.to_i - e[2] if e.present?
    when :leaving then nil
    end
  end

  def group_by_team
    eg = @events.group_by(&:first)
    tg = @turns.group_by(&:first)
    keys = (eg.keys + tg.keys).uniq.sort
    Hash[keys.map do |k|
      [k, Stats.new(eg[k] || [], tg[k] || [], self.mode)]
    end]
  end

  def last_driver_id
    case @mode
    when :both
      e = @events.select{|e| e[3] == 'arriving'}[-2]
      e[1] if e.present?
    when :leaving
      e = @events.select{|e| e[3] == 'leaving'}[-2]
      e[1] if e.present?
    end
  end

  def last_drive_time
    @turns.map(&:third)[-1]
  end

  def total_drive_time
    @turns.map(&:third).reduce(&:+)
  end
end
