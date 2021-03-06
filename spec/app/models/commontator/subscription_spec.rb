require 'test_helper'

module Commontator
  describe Subscription do
    before do
      setup_model_spec
      @subscription = Subscription.new
      @subscription.thread = @thread
      @subscription.subscriber = @user
    end
    
    it 'must count unread comments' do
      @subscription.unread.must_equal 0
      
      @subscription.add_unread
      
      @subscription.unread.must_equal 1
      
      @subscription.add_unread
      
      @subscription.unread.must_equal 2
      
      @subscription.mark_as_read
      
      @subscription.unread.must_equal 0
    end
  end
end
