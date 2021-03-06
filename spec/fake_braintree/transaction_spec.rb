require 'spec_helper'

describe FakeBraintree::SinatraApp do
  context "Braintree::Transaction.sale" do
    it "successfully creates a transaction" do
      result = Braintree::Transaction.sale(:payment_method_token => cc_token, :amount => 10.00)
      result.should be_success
    end

    context "when all cards are declined" do
      before { FakeBraintree.decline_all_cards! }

      it "fails" do
        result = Braintree::Transaction.sale(:payment_method_token => cc_token, :amount => 10.00)
        result.should_not be_success
      end
    end
  end
end

describe FakeBraintree::SinatraApp do
  context "Braintree::Transaction.refund" do
    it "successfully refunds a transaction" do
      result = Braintree::Transaction.refund(create_id('foobar'), '1')
      result.should be_success
    end
  end
end

describe FakeBraintree::SinatraApp do
  context "Braintree::Transaction.void" do
    it "successfully voids a transaction" do
      result = Braintree::Transaction.void(create_id('foobar'))
      result.should be_success
    end
  end
end

describe FakeBraintree::SinatraApp do
  context "Braintree::Transaction.find" do
    it "can find a created sale" do
      id = create_transaction.id
      result = Braintree::Transaction.find(id)
      result.amount.should == amount
    end

    it "can find >1 transaction" do
      Braintree::Transaction.find(create_transaction.id).should be
      Braintree::Transaction.find(create_transaction.id).should be
    end

    it "raises an error when the transaction does not exist" do
      expect { Braintree::Transaction.find('foobar') }.to raise_error(Braintree::NotFoundError)
    end

    def create_transaction
      Braintree::Transaction.sale(:payment_method_token => cc_token, :amount => amount).transaction
    end

    let(:amount) { 10.00 }
  end
end
