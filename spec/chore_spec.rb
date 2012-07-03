require 'chore'
require 'chore/store'

describe Chore do

  before :each do
    # Fake out the network code and submit directly to store
    Chore.stub(:send) do |args|
      json = Chore.sanitize(args)
      and_back = JSON::parse(json)
      Chore::Store.update_chore(and_back)
    end
  end


  it "should deliver a normal sized message" do
    Chore.status(:normal_message, "abracadabra")
    chore = Chore::Store.get_chore :normal_message
    status = chore[:notes].detect { |note| note.match(/^Status: (.*)/) }
    status.should == "Status: abracadabra"
  end
  
  it "should truncate a large message" do
    long_message = "abracadabra" * 1024
    Chore.status(:long_message, long_message )
    chore = Chore::Store.get_chore :long_message
    status = chore[:notes].detect { |note| note.match(/^Status: (.*)/) }
    status.should_not == "Status: " + long_message
    status.length.should == 1024 + "Status: ".length
  end
  
end
