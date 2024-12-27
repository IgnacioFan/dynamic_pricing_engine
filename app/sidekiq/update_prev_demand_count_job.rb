# This job runs every 2 hours
#
class UpdatePrevDemandCountJob
  include Sidekiq::Job
  sidekiq_options retry: 2

  def perform
    Product.where(demand_level: :high).each { |p|
      p.update!(previous_demand_count: [ p.current_demand_count, p.previous_demand_count ].max)
    }
  end
end
