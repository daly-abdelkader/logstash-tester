require "logstash/devutils/rspec/spec_helper"
require "rspec/expectations"
require 'json'

# Load the test cases
filter_data = Dir[ENV["DATA_TEST"]]

def run_case(tcase, ignore, data_file, i)
  input = tcase['in']

  msg_header = "[#{File.basename(data_file)}##{i}]"

   sample(input) do
    expected = tcase['out']
    expected_fields = expected.keys

    # Handle no results (for example, when a line is voluntarily dropped)
    lsresult = results.any? ? results[0] : {}
	hash_lsresult=lsresult.to_hash
    result_fields = hash_lsresult.keys.select { |f| not ignore.include?(f) }

    # test for grokparsefailures
	if hash_lsresult['tags']
		msg = "\n#{msg_header} Unexpected exception appears\nException generated: #{hash_lsresult['tags']}\n--"
		expect(hash_lsresult['tags']).not_to include('_grokparsefailure'), msg
		expect(hash_lsresult['tags']).not_to include('_rubyexception'), msg
	end

    # Test for presence of expected fields
    missing = expected_fields.select { |f| not result_fields.include?(f) }
    msg = "\n#{msg_header} Fields missing in logstash output: #{missing}\nComplete logstash output: #{hash_lsresult}\n--"
    expect(missing).to be_empty, msg

    # Test for absence of unknown fields
    extra = result_fields.select { |f| not expected_fields.include?(f) }
    msg = "\n#{msg_header} Unexpected fields in logstash output: #{extra}\nComplete logstash output: #{hash_lsresult}\n--"
    expect(extra).to be_empty, msg

    # Test individual field values
    expected.each do |name,value|
      msg = "\n#{msg_header} Field value mismatch: '#{name}'\nExpected: #{value} (#{value.class})\nGot: #{hash_lsresult[name]} (#{hash_lsresult[name].class})\n\n--"
      expect(hash_lsresult[name].to_s).to eq(value.to_s), msg
    end
  end
end

filter_data.each do |data_file|
  # Count test cases in this file
  test_case = JSON.parse(File.read(data_file))
  @@configuration = String.new
  @@configuration << File.read('/opt/logstash/rspec-tests/filters/' + test_case['filter_name'])
  (0..(test_case['cases'].length-1)).each do |i|
    describe "#{File.basename(data_file)}##{i}" do
      config(@@configuration)
      test_case = JSON.parse(File.read(data_file))
      run_case(test_case['cases'][i], test_case['ignore'], data_file, i)
    end
  end
end