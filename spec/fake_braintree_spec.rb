require 'spec_helper'

describe FakeBraintree, ".decline_all_cards!" do
  before { FakeBraintree.decline_all_cards! }

  it "declines all cards" do
    create_sale.should_not be_success
  end

  it "stops declining cards after clear! is called" do
    FakeBraintree.clear!
    create_sale.should be_success
  end

  def create_sale
    Braintree::CreditCard.sale(cc_token, :amount => 10.00)
  end
end

describe FakeBraintree, ".log_file_path" do
  it "is tmp/log" do
    FakeBraintree.log_file_path.should == 'tmp/log'
  end
end

describe Braintree::Configuration do
  subject { Braintree::Configuration }

  it "is running in the development environment" do
    subject.environment.should == :development
  end

  it "has some fake API credentials" do
    subject.merchant_id.should == "xxx"
    subject.public_key.should == "xxx"
    subject.private_key.should == "xxx"
  end
end

describe FakeBraintree do
  it "creates a log file" do
    File.exist?(FakeBraintree.log_file_path).should == true
  end

  it "logs to the correct path" do
    Braintree::Configuration.logger.info('Logger test')
    File.readlines(FakeBraintree.log_file_path).last.should == "Logger test\n"
  end
end

describe FakeBraintree, ".clear_log!" do
  it "clears the log file" do
    write_to_log
    subject.clear_log!
    File.read(FakeBraintree.log_file_path).should == ""
  end

  it "is called by clear!" do
    FakeBraintree.expects(:clear_log!)
    FakeBraintree.clear!
  end

  def write_to_log
    Braintree::Configuration.logger.info('foo bar baz')
  end
end

describe FakeBraintree, "VALID_CREDIT_CARDS" do
  it "includes only credit cards that are valid in the Braintree sandbox" do
    FakeBraintree::VALID_CREDIT_CARDS.sort.should == valid_credit_cards.sort
  end

  let(:valid_credit_cards) do
    %w(4111111111111111 4005519200000004
       4009348888881881 4012000033330026
       4012000077777777 4012888888881881
       4217651111111119 4500600000000061
       5555555555554444 378282246310005
       371449635398431 6011111111111117
       3530111333300000
      )
  end
end

describe FakeBraintree, ".failure_response" do
  it "can be called with no arguments" do
    expect { FakeBraintree.failure_response }.not_to raise_error
  end
end

describe FakeBraintree, ".generate_transaction" do
  it "allows setting the subscription id" do
    transaction = FakeBraintree.generate_transaction(:subscription_id => 'foobar')
    transaction['subscription_id'].should == 'foobar'
  end

  it "allows setting created_at" do
    time = Time.now
    transaction = FakeBraintree.generate_transaction(:created_at => time)
    transaction['created_at'].should == time
  end

  it "sets created_at to Time.now by default" do
    Timecop.freeze do
      transaction = FakeBraintree.generate_transaction
      transaction['created_at'].should == Time.now
    end
  end

  it "has the correct amount" do
    transaction = FakeBraintree.generate_transaction(:amount => "20.00")
    transaction['amount'].should == "20.00"
  end

  it "allows no arguments" do
    expect { FakeBraintree.generate_transaction }.not_to raise_error
  end

  context "status_history" do
    it "returns a hash with a status_history key" do
      FakeBraintree.generate_transaction(:amount => '20').should have_key('status_history')
    end

    it "has a timestamp of Time.now" do
      Timecop.freeze do
        transaction = FakeBraintree.generate_transaction(:status => Braintree::Transaction::Status::Failed,
                                                         :subscription_id => 'my_subscription_id')
        transaction['status_history'].first['timestamp'].should == Time.now
      end
    end

    it "has the desired amount" do
      transaction = FakeBraintree.generate_transaction(:amount => '20.00')
      transaction['status_history'].first['amount'].should == '20.00'
    end

    it "has the desired status" do
      status = Braintree::Transaction::Status::Failed
      transaction = FakeBraintree.generate_transaction(:status => status)
      transaction['status_history'].first['status'].should == status
    end
  end
end

describe FakeBraintree, ".settle_transaction" do
  it 'updates the status to settled' do
    status = Braintree::Transaction::Status::Settled
    t = Braintree::Transaction.sale(:payment_method_token => cc_token,
                                     :amount => 10.00,
                                     :options => {
                                      :submit_for_settlement => true
                                     })
    result = FakeBraintree.settle_transaction(t.transaction.id)
    FakeBraintree.registry.transactions[t.transaction.id]['status'].should == status
  end
end
