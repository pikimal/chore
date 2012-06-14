require 'chore/store'

describe Chore::Store do
  context "notes" do
    it "should understand :do_every" do
      Chore::Store.update_chore ["start", "do_every_chore", {"do_every"=>60, "start_time"=> Time.now().to_i}]
      chore = Chore::Store.get_chore "do_every_chore"
      chore[:job].should == "do_every_chore"
      chore[:notes].should include "Should run every 1 minute"
    end

    it "should understand :grace_period" do
      Chore::Store.update_chore ["start", "grace_period_chore", {"do_every"=>1, "grace_period"=>2400, "start_time"=> Time.now().to_i}]
      sleep(2) #Timecop?
      chore = Chore::Store.get_chore "grace_period_chore"
      chore[:job].should == "grace_period_chore"
      chore[:notes].should include "Job should run every 1 second, but has a grace period of 40 minutes"
    end
    
    it "should print human understandible deadlines" do
      Chore::Store.update_chore ["start", "crazy_time_chore", {"do_every"=>12345678, "start_time"=> Time.now().to_i}]
      chore = Chore::Store.get_chore "crazy_time_chore"
      chore[:job].should == "crazy_time_chore"
      chore[:notes].should include "Should run every 2 days 21 hours 21 minutes 18 seconds"
    end
    
    it "should add a note when we fail" do
      Chore::Store.update_chore ["start", "exceptional_chore", {"start_time"=> Time.now().to_i}]
      Chore::Store.update_chore ["fail", "exceptional_chore", {"fail_time"=>Time.now.to_i}]
      chore = Chore::Store.get_chore "exceptional_chore"
      
      chore[:notes].should include "FAILED!!!"
    end
    
    it "should add a note when we fail with error message" do
      Chore::Store.update_chore ["start", "exceptional_chore_2", {"start_time"=> Time.now().to_i}]
      Chore::Store.update_chore ["fail", "exceptional_chore_2", {"error"=>"Another freaking nil error", "fail_time"=>Time.now.to_i}]
      chore = Chore::Store.get_chore "exceptional_chore_2"
      
      chore[:notes].should include "Another freaking nil error"
    end

    it "should recored status updates" do
      Chore::Store.update_chore ["start", "updating_task", {"start_time"=>1339712405}]

      Chore::Store.update_chore ["status_update", "updating_task", {"status_note"=>"Step one complete"}]
      chore = Chore::Store.get_chore("updating_task")
      chore[:notes].should include "Status: Step one complete"

      Chore::Store.update_chore ["status_update", "updating_task", {"status_note"=>"Step two complete"}]
      chore = Chore::Store.get_chore("updating_task")
      chore[:notes].should_not include "Status: Step one complete"
      chore[:notes].should include "Status: Step two complete"
    end
  end

  context "states" do
    it "should be green when started" do
      Chore::Store.update_chore ["start", "logrotate", {"start_time"=>Time.now().to_i}]
      chore = Chore::Store.get_chore('logrotate')
      chore[:state].should == :green
    end

    it "should be red when :do_every is late" do
      Chore::Store.update_chore ["start", "late_chore", {"do_every" => 1, "start_time"=>Time.now().to_i - 10}]
      chore = Chore::Store.get_chore('late_chore')
      chore[:state].should == :red
    end
    
    it "should be yellow when :do_every is late, but grace period is good" do
      Chore::Store.update_chore ["start", "late_chore", {"do_every" => 1, "grace_period" => 20, "start_time"=>Time.now().to_i - 10}]
      chore = Chore::Store.get_chore('late_chore')
      chore[:state].should == :yellow
    end
    
    it "should be red when we fail" do
      Chore::Store.update_chore ["start", "failure", {"start_time"=> Time.now().to_i}]
      Chore::Store.update_chore ["fail", "failure", {"error"=>"Another freaking nil error", "fail_time"=>Time.now.to_i}]
      chore = Chore::Store.get_chore "failure"

      chore[:state].should == :red
    end
    
    it "should be green if we've finished with no specified finish time" do
      Chore::Store.update_chore ["start", "finish_anytime", {"start_time"=>Time.now().to_i}]
      Chore::Store.update_chore ["finish", "finish_anytime", {"finish_time"=>Time.now().to_i}]
      chore = Chore::Store.get_chore("finish_anytime")
      chore[:state].should == :green
    end

    it "should be green if we haven't exceeded finish time" do
      Chore::Store.update_chore ["start", "finish_later", {"finish_in"=>12345678, "start_time"=>Time.now().to_i}]
      Chore::Store.update_chore ["finish", "finish_later", {"finish_time"=>Time.now().to_i}]
      chore = Chore::Store.get_chore("finish_later")
      chore[:state].should == :green
    end
    
    it "should be red if we have exceeded finish time" do
      Chore::Store.update_chore ["start", "finish_earlier", {"finish_in"=>1, "start_time"=>Time.now().to_i - 12345678}]
      Chore::Store.update_chore ["finish", "finish_earlier", {"finish_time"=>Time.now().to_i}]
      chore = Chore::Store.get_chore("finish_earlier")
      chore[:state].should == :red
    end
    

  end
end
