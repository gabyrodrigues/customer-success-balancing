require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    customer_success_available = fetch_all_customer_success_available(@customer_success, @away_customer_success)
    customers_ordered = order_by_score(@customers)
    customer_success_available_ordered = order_by_score(customer_success_available)

    customer_success_available_ordered.each do |cs|
      cs[:customers] = []
    end

    customers_ordered.each do |customer|
      customer_cs = find_customer_cs(customer_success_available_ordered, customer)
      if customer_cs
        customer_cs[:customers].push(customer[:id])
      end
    end

    most_customers_cs = calculate_cs_with_most_customers(customer_success_available_ordered)

    most_customers_cs[:id]
  end

  def calculate_cs_with_most_customers(customer_success)
    customer_success.inject({ id: nil, customers: [] }) do |acc, cs|
      if cs[:customers].length > acc[:customers].length
        { id: cs[:id], customers: cs[:customers] }
      elsif cs[:customers].length == acc[:customers].length
        { id: 0, customers: acc[:customers] }
      else
        acc
      end
    end
  end

  def find_customer_cs(customer_success, customer)
    customer_success.find{ |cs| customer[:score] <= cs[:score] }
  end

  def fetch_all_customer_success_available(customer_success, away_customer_success)
    away_customer_success.any? ? customer_success.reject { |cs| away_customer_success.include?(cs[:id]) } : customer_success
  end
 
  def order_by_score(items)
    items.any? ? items.sort { |a, b| a[:score].to_i <=> b[:score].to_i } : []
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
