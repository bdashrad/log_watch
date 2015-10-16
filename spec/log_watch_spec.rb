require 'spec_helper'

describe LogWatch do
  it 'has a version number' do
    expect(LogWatch::VERSION).not_to be nil
  end

  before :each do
    @mon = LogWatch::Monitor.new
    @logdata = %(192.168.1.3 ident brad [18/Feb/2000:13:33:37 -0600] "POST /wow/swag HTTP/1.0" 200 5073
192.168.1.3 ident brad [18/Feb/2000:13:33:37 -0600] "POST /wow/swag HTTP/1.0" 200 5073
192.168.1.3 ident brad [18/Feb/2000:13:33:37 -0600] "POST /wow/swag HTTP/1.0" 200 5073
192.168.1.3 ident brad [18/Feb/2000:13:33:37 -0600] "POST /wow/swag HTTP/1.0" 200 5073
127.0.0.1 - frank [10/Oct/2000:13:55:36 -0700] "GET /pages/apache_pb.gif HTTP/1.0" 200 2326
192.168.1.3 - - [18/Feb/2000:13:33:37 -0600] "GET / HTTP/1.0" 200 5073
127.0.0.1 - frank [10/Oct/2000:13:55:36 -0700] "GET /pages/apache_pb.gif HTTP/1.0" 200 2326
192.168.1.3 - - [18/Feb/2000:13:33:37 -0600] "GET / HTTP/1.0" 200 5073
127.0.0.1 - frank [10/Oct/2000:13:55:36 -0700] "GET /wow/apache_pb.gif HTTP/1.0" 200 2326
192.168.1.3 - - [18/Feb/2000:13:33:37 -0600] "GET /yup HTTP/1.0" 200 5073
192.168.1.3 ident brad [18/Feb/5030:13:33:37 -0600] "GET /yup HTTP/1.0" 503 5073
192.168.1.3 ident brad [18/Feb/5030:13:33:37 -0600] "GET /yup HTTP/1.0" 503 5073
192.168.1.3 ident brad [18/Feb/2000:13:33:37 -0600] "GET /pages/stuf/yup HTTP/1.0" 200 5073
192.168.1.3 ident brad [18/Feb/4040:13:33:37 -0600] "GET /yolo/swag HTTP/1.0" 404 5073
192.168.1.3 ident brad [18/Feb/4040:13:33:37 -0600] "GET /yolo/swag HTTP/1.0" 404 5073
192.168.1.3 ident brad [18/Feb/4040:13:33:37 -0600] "GET /things/yolo/swag HTTP/1.0" 404 5073)

    # @loglines = [
    #   {
    #     'ip' => '192.168.1.3',
    #     'identity' => 'ident',
    #     'user' => 'brad',
    #     'time' => '18/Feb/2000:13:33:37 -0600',
    #     'verb' => 'POST',
    #     'url' => '/wow/swag',
    #     'version' => 'HTTP/1.0',
    #     'status' => '200',
    #     'bytes' => '5073',
    #     'section' => '/wow'
    #   },
    #   {
    #     'ip' => '192.168.1.3',
    #     'identity' => 'ident',
    #     'user' => 'brad',
    #     'time' => '18/Feb/2000:13:33:37
    #     -0600',
    #     'verb' => 'POST',
    #     'url' => '/yolo/swag',
    #     'version' => 'HTTP/1.0',
    #     'status' => '200',
    #     'bytes' => '5073',
    #     'section' => '/yolo'
    #   }
    # ]
  end

  it 'injests log lines' do
    @logdata.split("\n").each do |log|
      @mon.parse_log_data(log)
    end
    expect(@mon.instance_variable_get(:@loglines).length).to eq(16)
  end
end
