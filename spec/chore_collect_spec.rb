require 'chore'
require 'chore/server'

describe ChoreCollect do
  before :each do
    # We're not testing event-machine here
    ChoreCollect.stub(:chore_collect) 
    
    class FakeCollector
      include ChoreCollect
    end

    @collector = FakeCollector.new
  end
  
  it "should not blow up on truncated message" do
    @collector.stub(:warn) # Don't show warning in rspec output
    @collector.receive_data([:foo, :status_update, {:status => "abracadabra"*1024}].to_json()[0..-3])
  end

  it "should not blow up on valid message" do
    @collector.receive_data([:foo, :status_update, {:status => "abracadabra"}].to_json())
  end
end
