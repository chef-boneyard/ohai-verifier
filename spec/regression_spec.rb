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
      if next_data.respond_to?(:[])
        next_data = next_data[next_path]
      else
        path_description = "['#{deep_path.join("', '")}']"
        searched_path_des = "['#{searched_path.join("', '")}']"
        raise "Could not fetch data at path #{path_description}\n" +
          "Searched up to #{searched_path_des}"
      end
    end
    next_data
  end

  ANYTHING = Object.new

  def ANYTHING.==(other)
    true
  end

  FUZZY_MATCHES = []

  def self.fuzzy_matches
    FUZZY_MATCHES
  end

  def self.fuzzy_match(*path)
    FUZZY_MATCHES << path
  end

  def self.fuzzy_match?(path)
    fuzzy_matches.any? do |fuzzy_match_path|
      fuzzy_match_path == path
    end
  end

  fuzzy_match 'chef_packages', 'ohai', 'version'
  fuzzy_match 'ohai_time'
  fuzzy_match 'uptime'
  fuzzy_match 'uptime_seconds'
  fuzzy_match 'network', 'settings', 'net.inet.tcp.pcbcount'
  fuzzy_match 'network', 'settings', 'net.inet.tcp.newreno_sockets'
  fuzzy_match 'network', 'settings', 'net.inet.tcp.tcp_resched_timerlist'
  fuzzy_match 'counters', 'network', 'interfaces', ANYTHING, 'rx', 'packets'
  fuzzy_match 'counters', 'network', 'interfaces', ANYTHING, 'rx', 'bytes'
  fuzzy_match 'counters', 'network', 'interfaces', ANYTHING, 'rx', 'errors'
  fuzzy_match 'counters', 'network', 'interfaces', ANYTHING, 'rx', 'collisions'
  fuzzy_match 'counters', 'network', 'interfaces', ANYTHING, 'tx', 'packets'
  fuzzy_match 'counters', 'network', 'interfaces', ANYTHING, 'tx', 'bytes'
  fuzzy_match 'counters', 'network', 'interfaces', ANYTHING, 'tx', 'errors'
  fuzzy_match 'counters', 'network', 'interfaces', ANYTHING, 'tx', 'collisions'
  fuzzy_match 'filesystem', ANYTHING, 'kb_used'
  fuzzy_match 'filesystem', ANYTHING, 'kb_available'
  fuzzy_match 'system_profile', ANYTHING, '_SPCompletionInterval'
  fuzzy_match 'system_profile', ANYTHING, '_timeStamp'
  fuzzy_match 'items', ANYTHING, '_SPCompletionInterval'
  fuzzy_match 'items', ANYTHING, '_timeStamp'

  fuzzy_match 'memory', 'free'
  fuzzy_match 'memory', 'buffers'
  fuzzy_match 'memory', 'slab_reclaimable'
  fuzzy_match 'memory', 'cached'
  fuzzy_match 'memory', 'active'
  fuzzy_match 'memory', 'inactive'
  fuzzy_match 'memory', 'dirty'
  fuzzy_match 'memory', 'anon_pages'
  fuzzy_match 'memory', 'mapped'
  fuzzy_match 'memory', 'slab'
  fuzzy_match 'memory', 'slab_unreclaim'
  fuzzy_match 'memory', 'page_tables'
  fuzzy_match 'memory', 'committed_as'
  fuzzy_match 'memory', 'cache'
  fuzzy_match 'memory', 'wired'
  fuzzy_match 'idletime_seconds'
  fuzzy_match 'idletime'

  fuzzy_match 'kernel', "os_info", "free_physical_memory"
  fuzzy_match 'kernel', "os_info", "free_virtual_memory"
  fuzzy_match 'kernel', "os_info", "free_space_in_paging_files"
  fuzzy_match 'kernel', "os_info", "local_date_time"
  fuzzy_match 'kernel', "os_info", "number_of_processes"

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

            if fuzzy_match?(expected_path)
              it "has a similar value for #{path_des}" do
                new_value = deep_fetch(new_data, expected_path)
                new_value.should_not be_nil
                new_value.class.should == expected_value.class
              end
            else
              it "has the same value for #{path_des}" do
                new_value = deep_fetch(new_data, expected_path)
                new_value.should == expected_value
              end
            end

          end

        end
      end
    end
  end
end
