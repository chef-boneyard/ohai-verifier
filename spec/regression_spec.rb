require 'yajl'
require 'pp'

RESULTS_DIR = File.expand_path("../../test-result", __FILE__)

describe "Ohai Output Comparison" do

  def self.read_result(path)
    File.open(path, "r") { |f| Yajl::Parser.parse(f) }
  end

  def self.leaf_nodes_from(ohai_data, leaves_by_path={}, nesting=[])
    case ohai_data
    when Hash
      ohai_data.each {|k,v| leaf_nodes_from(v, leaves_by_path, nesting + [k]) }
    when Array
      ohai_data.each_with_index {|elem, i| leaf_nodes_from(elem, leaves_by_path, nesting + [i]) }
    else
      leaves_by_path[nesting] = ohai_data
    end
    leaves_by_path
  end

  def deep_fetch(nested_data, deep_path)
    path = deep_path.dup
    searched_path = []
    next_data = nested_data
    while next_path = path.shift
      searched_path << next_path
      if next_data.respond_to?(:[]) && next_data = next_data[next_path]
        # continue
      else
        path_description = "['#{deep_path.join("', '")}']"
        searched_path_des = "['#{searched_path.join("', '")}']"
        raise "Could not fetch data at path #{path_description}\n" +
          "Searched up to #{searched_path_des}"
      end
    end
    next_data
  end

  platforms = Dir["#{RESULTS_DIR}/*"]

  platforms.each do |platform_path|
    describe "On platform #{File.basename(platform_path)}" do

      test_runs = Dir["#{platform_path}/*"]
      test_runs.each do |run_id_path|

        describe "for test sample #{File.basename(run_id_path)}" do

          old_data = read_result(File.join(run_id_path, "old_ohai.json"))
          new_data = read_result(File.join(run_id_path, "new_ohai.json"))

          old_leaf_nodes = leaf_nodes_from(old_data)

          old_leaf_nodes.each do |expected_path, expected_value|

            path_des = "['#{expected_path.join("', '")}']"

            it "has the same value for #{path_des}" do
              deep_fetch(new_data, expected_path).should == expected_value
            end

          end

        end
      end
    end
  end
end
