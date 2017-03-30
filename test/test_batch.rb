require 'helper'

class TestBatch < LCTestCase

  def test_initialize
    batch = LC::Batch.new
    assert_equal batch.class, LC::Batch
    assert_equal LC.client, batch.client

    batch = LC::Batch.new(LC::Client.new)
    assert_equal batch.class, LC::Batch
    assert_not_equal LC.client, batch.client
  end

  def test_add_request
    batch = LC::Batch.new
    batch.add_request({
      :method => "POST",
      :path => "/1/classes/GameScore",
      :body => {
        :score => 1337,
        :playerName => "Sean Plott"
      }
    })
    batch.add_request({
      :method => "POST",
      :path => "/1/classes/GameScore",
      :body => {
        :score => 1338,
        :playerName => "ZeroCool"
      }
    })
    assert_equal batch.requests.class, Array
    assert_equal batch.requests.length, 2
    assert_equal batch.requests.first[:path], "/1/classes/GameScore"
  end

  def test_protocol_uri
    uri = LC::Protocol.batch_request_uri
    assert_equal uri, "/1.1/batch"
  end

  def test_run
    VCR.use_cassette('test_batch_run', :record => :new_episodes) do
      batch = LC::Batch.new
      batch.add_request({
        "method" => "POST",
        "path" => "/1/classes/GameScore",
        "body" => {
          "score" => 1337,
          "playerName" => "Sean Plott"
        }
      })
      resp = batch.run!
      assert_equal resp.length, batch.requests.length
      assert resp.first["success"]
      assert_equal resp.first["success"]["objectId"].class, String
    end
  end

  def test_create_object
    VCR.use_cassette('test_batch_create_object', :record => :new_episodes) do
      objects = [1, 2, 3, 4, 5].map do |i|
        p = LC::Object.new("BatchTestObject")
        p["foo"] = "#{i}"
        p
      end
      batch = LC::Batch.new
      objects.each do |obj|
        batch.create_object(obj)
      end
      resp = batch.run!
      assert_equal Array, resp.class
      assert_equal resp.first["success"]["objectId"].class, String
    end
  end

  def test_update_object
    VCR.use_cassette('test_batch_update_object', :record => :new_episodes) do
      objects = [1, 2, 3, 4, 5].map do |i|
        p = LC::Object.new("BatchTestObject")
        p["foo"] = "#{i}"
        p.save
        p
      end
      objects.map do |obj|
        obj["foo"] = "updated"
      end
      batch = LC::Batch.new
      objects.each do |obj|
        batch.update_object(obj)
      end
      resp = batch.run!
      assert_equal Array, resp.class
      assert_equal resp.first["success"]["updatedAt"].class, String
    end
  end

  def test_update_nils_delete_keys
    VCR.use_cassette('test_batch_update_nils_delete_keys', :record => :new_episodes) do
      post = LC::Object.new("BatchTestObject")
      post["foo"] = "1"
      post.save

      post["foo"] = nil
      batch = LC::Batch.new
      batch.update_object(post)
      batch.run!

      assert_false post.refresh.keys.include?("foo")
    end
  end

  def test_delete_object
    VCR.use_cassette('test_batch_delete_object', :record => :new_episodes) do
      objects = [1, 2, 3, 4, 5].map do |i|
        p = LC::Object.new("BatchTestObject")
        p["foo"] = "#{i}"
        p.save
        p
      end
      batch = LC::Batch.new
      objects.each do |obj|
        batch.delete_object(obj)
      end
      resp = batch.run!
      assert_equal Array, resp.class
      assert_equal resp.first["success"], {}
    end
  end

end
