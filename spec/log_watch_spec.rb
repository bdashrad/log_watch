require 'spec_helper'

describe LogWatch do
  it 'has a version number' do
    expect(LogWatch::VERSION).not_to be nil
  end

  before :each do
    @mon = LogWatch::Monitor.new
    @logdata =
%(192.168.1.3 - b [18/Feb/2000:13:33:37 -0600] "POST /wow/swag HTTP/1.0" 200 503
192.168.1.3 i b [18/Feb/2000:13:33:37 -0600] "POST /wow/swag HTTP/1.0" 200 5073
192.168.1.3 i b [18/Feb/2000:13:33:37 -0600] "POST /wow/swag HTTP/1.0" 200 5073
192.168.1.3 i b [18/Feb/2000:13:33:37 -0600] "POST /wow/swag HTTP/1.0" 200 5073
127.0.0.1 - fr [10/Oct/2000:13:55:36 -0700] "GET /pages/pb.gif HTTP/1.0" 200 26
192.168.1.3 - - [18/Feb/2000:13:33:37 -0600] "GET / HTTP/1.0" 200 5073
127.0.0.1 - f [10/Oct/2000:13:55:36 -0700] "GET /pages/pb.gif HTTP/1.0" 200 2326
192.168.1.3 - - [18/Feb/2000:13:33:37 -0600] "GET / HTTP/1.0" 200 5073
127.0.0.1 - f [10/Oct/2000:13:55:36 -0700] "GET /wow/pb.gif HTTP/1.0" 200 2326
192.168.1.3 - - [18/Feb/2000:13:33:37 -0600] "GET /yup HTTP/1.0" 200 5073
192.168.1.3 ident brad [18/Feb/5030:13:33:37 -0600] "GET /yup HTTP/1.0" 503 5073
192.168.1.3 ident brad [18/Feb/5030:13:33:37 -0600] "GET /yup HTTP/1.0" 503 5073
192.168.1.3 - - [18/Feb/2000:13:33:37 -0600] "GET /pages/yup HTTP/1.0" 200 5073
192.168.1.3 - - [18/Feb/4040:13:33:37 -0600] "GET /yolo/swag HTTP/1.0" 404 5073
192.168.1.3 - - [18/Feb/4040:13:33:37 -0600] "GET /yolo/swag HTTP/1.0" 404 5073
192.168.1.3 - - [18/Feb/4040:13:33:37 -0600] "GET /things/ag HTTP/1.0" 404 5073)

    loglines = []
    @logdata.split("\n").each do |log|
      loglines.push(@mon.parse_log_data(log))
    end
    @mon.instance_variable_set(:@loglines, loglines)

    counter =
      [
        1445010210,
        1445010211,
        1445010212,
        1445010213,
        1445010214,
        1445010215,
        1445010216,
        1445010217,
        1445010218,
        1445010219,
        1445010220,
        1445010221,
        1445010222,
        1445010223,
        1445010224,
        1445010225
      ]
    @mon.instance_variable_set(:@counter, counter)
  end

  it 'injests log lines' do
    expect(@mon.instance_variable_get(:@loglines).length).to eq(16)
  end

  it 'parses log lines' do
    parsed_data =
    {
      'ip' => '192.168.1.3',
      'identity' => '-',
      'user' => 'b',
      'time' => '18/Feb/2000:13:33:37 -0600',
      'verb' => 'POST',
      'url' => '/wow/swag',
      'version' => 'HTTP/1.0',
      'status' => '200',
      'bytes' => '503',
      'section' => '/wow'
    }
    log = @mon.parse_log_data(@logdata.split("\n").first)
    expect(log).to eq(parsed_data)
  end

  it 'counts section hits' do
    sections =
      {
        '/wow' => 5,
        '/pages' => 3,
        '/' => 2,
        '/yup' => 3,
        '/yolo' => 2,
        '/things' => 1
      }
    @mon.count_section_hits
    expect(@mon.instance_variable_get(:@section_hits)).to eq(sections)
  end

  it 'counts http verbs' do
    verbs = { 'POST' => 4, 'GET' => 12 }
    @mon.count_section_hits
    expect(@mon.instance_variable_get(:@verbs)).to eq(verbs)
  end

  it 'counts http status codes' do
    status = { '200' => 11, '503' => 2, '404' => 3 }
    @mon.count_section_hits
    expect(@mon.instance_variable_get(:@status)).to eq(status)
  end

  it 'alerts when thresholds are crossed' do
    @mon.check_alert
    expect(@mon.instance_variable_get(:@alert)).to eq(true)
  end

  it 'deletes count of alerts older than 2 minutes' do
    @mon.count_hits_2m(1445010341)
    expect(@mon.instance_variable_get(:@counter).length).to eq(5)
  end

  it 'recovers when thresholds are normal' do
    @mon.instance_variable_set(:@alert, true)
    @mon.count_hits_2m(1445010341)
    @mon.check_alert
    expect(@mon.instance_variable_get(:@alert)).to eq(false)
  end
end
