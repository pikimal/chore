require 'chore'
require 'chore/store'

describe Chore::Store do
  
  before :each do
    # Fake out the network code and submit directly to store
    Chore.stub(:send) do |args|
      json = Chore.sanitize(args)
      and_back = JSON::parse(json)
      Chore::Store.update_chore(and_back)
    end
  end

  it "test" do
    Chore.start(:foo)
  end

  context "notes" do
    it "should understand :do_every" do
      Chore.start(:do_every_chore, :do_every => 60)
      chore = Chore::Store.get_chore :do_every_chore
      chore[:job].should == "do_every_chore"
      chore[:notes].should include "Should run every 1 minute"
    end

    it "should understand :grace_period" do
      Chore.start(:grace_period_chore, :do_every =>1, :grace_period => 2400, :start_time => Time.now().to_i - 10)
      chore = Chore::Store.get_chore :grace_period_chore
      chore[:job].should == "grace_period_chore"
      chore[:notes].should include "Job should run every 1 second, but has a grace period of 40 minutes"
    end
    
    it "should print human understandible deadlines" do
      Chore.start(:crazy_time_chore, :do_every => 12345678)
      chore = Chore::Store.get_chore :crazy_time_chore
      chore[:job].should == "crazy_time_chore"
      chore[:notes].should include "Should run every 2 days 21 hours 21 minutes 18 seconds"
    end
    
    it "should add a note when we fail" do
      Chore.start(:exceptional_chore)
      Chore.fail(:exceptional_chore)
      chore = Chore::Store.get_chore :exceptional_chore
      
      chore[:notes].should include "FAILED!!!"
    end
    
    it "should add a note when we fail with error message" do
      Chore.start(:exceptional_chore_2)
      Chore.fail(:exceptional_chore_2, :error => "Another freaking nil error")
      chore = Chore::Store.get_chore :exceptional_chore_2
      
      chore[:notes].should include "Another freaking nil error"
    end

    it "should recored status updates" do
      Chore.start(:updating_task)

      Chore.status(:updating_task, "Step one complete")
      chore = Chore::Store.get_chore(:updating_task)
      chore[:notes].should include "Status: Step one complete"

      Chore.status(:updating_task, "Step two complete")
      chore = Chore::Store.get_chore(:updating_task)
      chore[:notes].should_not include "Status: Step one complete"
      chore[:notes].should include "Status: Step two complete"
    end
  end

  context "states" do
    it "should be green when started" do
      Chore.start(:logrotate)
      chore = Chore::Store.get_chore(:logrotate)
      chore[:state].should == :green
    end

    it "should be red when :do_every is late" do
      Chore.start("late_chore", :do_every => 1, :start_time => Time.now().to_i - 10)
      chore = Chore::Store.get_chore(:late_chore)
      chore[:state].should == :red
    end
    
    it "should be yellow when :do_every is late, but grace period is good" do
      Chore.start("late_chore", :do_every => 1, :grace_period => 20, :start_time =>Time.now().to_i - 10)
      chore = Chore::Store.get_chore(:late_chore)
      chore[:state].should == :yellow
    end
    
    it "should be red when we fail" do
      Chore.start(:failure)
      Chore.fail(:failure, :error => "Another freaking nil error")
      chore = Chore::Store.get_chore :failure

      chore[:state].should == :red
    end
    
    it "should be green if we've finished with no specified finish time" do
      Chore.start(:finish_anytime)
      Chore.finish(:finish_anytime)
      chore = Chore::Store.get_chore(:finish_anytime)
      chore[:state].should == :green
    end

    it "should be green if we haven't exceeded finish time" do
      Chore.start(:finish_later, "finish_in"=>12345678)
      Chore.finish(:finish_later)
      chore = Chore::Store.get_chore(:finish_later)
      chore[:state].should == :green
    end
    
    it "should be red if we have exceeded finish time" do
      Chore.start(:finish_earlier, :finish_in => 1, :start_time=>Time.now().to_i - 12345678)
      Chore.finish(:finish_earlier)
      chore = Chore::Store.get_chore(:finish_earlier)
      chore[:state].should == :red
    end
  end

  context "expiration" do
    it "monitor with pop should work" do
      Chore.monitor(:popped_task, :pop => true) {}
      Chore::Store.get_chore(:popped_task).should be_nil
    end
    
    it "monitor without pop should work" do
      Chore.monitor(:unpopped_task) {}
      Chore::Store.get_chore(:unpopped_task).should_not be_nil
    end

    it "manual pop should work" do
      Chore.start(:manual_pop)
      Chore::Store.get_chore(:manual_pop).should_not be_nil

      Chore.pop(:manual_pop)
      Chore::Store.get_chore(:manual_pop).should be_nil
    end
    
    it "shouldn't remove expired task before it's time" do
      Chore.start(:expire_later, :expire_in => Time.now.to_i + 12345678)
      Chore::Store.expire()
      Chore::Store.get_chore(:expire_later).should_not be_nil
    end

    it "should remove expired task when expired" do
      Chore.start(:expire_yesterday, :expire_in => 1, :start_time => Time.now.to_i - 12345678)
      Chore::Store.get_chore(:expire_yesterday).should_not be_nil
      Chore::Store.expire()
      Chore::Store.get_chore(:expire_yesterday).should be_nil
    end
  end

  context "monitor" do
    it "should record exception" do
      begin
        Chore.monitor(:AAAAAAAAA) do
          raise "AAAAAAA"
        end
      rescue Exception => ex
      end

      failed_chore = Chore::Store.get_chore(:AAAAAAAAA)
      failed_chore[:state].should == :red
      failed_chore[:status].should == :fail
    end

    it "should record finish" do
      Chore.monitor(:finish_cleanly) {}
      finished_chore = Chore::Store.get_chore(:finish_cleanly)
      finished_chore[:state].should == :green
      finished_chore[:status].should == :finish
    end
    
  end
end
