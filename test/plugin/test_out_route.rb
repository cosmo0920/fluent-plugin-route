require 'fluent/test'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_route'
require 'fluent/test/helpers'

class RouteOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    remove_tag_prefix t
    <route t1.*>
      remove_tag_prefix t1
      add_tag_prefix yay
    </route>
    <route t2.*>
      remove_tag_prefix t2
      add_tag_prefix foo
    </route>
    <route **>
      @label @primary
      copy
    </route>
    <route **>
      @label @backup
    </route>
  ]

  def create_driver(conf)
    d = Fluent::Test::Driver::Output.new(Fluent::Plugin::RouteOutput)
    Fluent::Engine.root_agent.define_singleton_method(:find_label) do |label_name|
      obj = Object.new
      obj.define_singleton_method(:event_router){ d.instance.router } # for test...
      obj
    end
    d.configure(conf, syntax: :v1)
  end

  def test_configure
    # TODO: write
  end

  def test_emit_t1
    d = create_driver(CONFIG)

    time = Time.parse("2011-11-11 11:11:11 UTC").to_i
    d.run(default_tag: "t.t1.test") do
      d.feed(time, {"a" => 1})
      d.feed(time, {"a" => 2})
    end

    events = d.events
    assert_equal 2, events.size

    assert_equal ["yay.test", time, {"a" => 1}], events[0]
    assert_equal ["yay.test", time, {"a" => 2}], events[1]
  end

  def test_emit_t2
    d = create_driver(CONFIG)

    time = event_time("2011-11-11 11:11:11 UTC")
    d.run(default_tag: "t.t2.test") do
      d.feed(time, {"a" => 1})
      d.feed(time, {"a" => 2})
    end

    events = d.events
    assert_equal 2, events.size

    assert_equal ["foo.test", time, {"a" => 1}], events[0]
    assert_equal ["foo.test", time, {"a" => 2}], events[1]
  end

  def test_emit_others
    d = create_driver(CONFIG)

    time = Time.parse("2011-11-11 11:11:11 UTC").to_i
    d.run(default_tag: "t.t3.test") do
      d.feed(time, {"a" => 1})
      d.feed(time, {"a" => 2})
    end

    events = d.events
    assert_equal 4, events.size

    assert_equal ["t3.test", time, {"a" => 1}], events[0]
    assert_equal ["t3.test", time, {"a" => 1}], events[1]
    assert_equal ["t3.test", time, {"a" => 2}], events[2]
    assert_equal ["t3.test", time, {"a" => 2}], events[3]
  end
end
