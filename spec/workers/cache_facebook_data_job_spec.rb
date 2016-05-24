# frozen_string_literal: true
require 'spec_helper'

describe CacheFacebookDataJob do
  let(:user) { create :user, access_token: 'test' }

  before do
    stub_http_request(:post, /graph.facebook.com/).to_return body: [
      { code: 200,
        headers: [{ name: 'Content-Type',
                    value: 'text/javascript; charset=UTF-8' }],
        body: '{}' },
      { code: 200,
        headers: [{ name: 'Content-Type',
                    value: 'text/javascript; charset=UTF-8' }],
        body: '{}' }
    ].to_json
  end

  it 'caches user data when they are nil' do
    expect(CacheFacebookDataJob.perform_now(user)).to be true
  end

  it 'caches user data when they are expired' do
    expect(CacheFacebookDataJob.perform_now(user)).to be true
    expect(CacheFacebookDataJob.perform_now(user)).to be false

    travel_to APP_CONFIG.facebook.cache_expiry_time.from_now + 1.second do
      expect(CacheFacebookDataJob.perform_now(user)).to be true
      expect(CacheFacebookDataJob.perform_now(user)).to be false
    end
  end

  it "doesn't cache user data when they are still valid" do
    user_with_fresh_data = create :user, access_token: 'test', facebook_data_cached_at: Time.current
    expect(CacheFacebookDataJob.perform_now(user_with_fresh_data)).to be false
  end

  it "doesn't fail when response is wrong" do
    stub_http_request(:post, /graph.facebook.com/).to_return status: 500
    expect(CacheFacebookDataJob.perform_now(user)).to be false
  end
end
