#!/bin/sh
# Minimal OpenClash overwrite: inject Zscaler classical rule-provider only.
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

LOG_TIP "Start Running Custom Overwrite Scripts (Zscaler-only bootstrap)..."
CONFIG_FILE="$1"

ruby -ryaml -e '
begin
  f = ARGV[0]
  d = YAML.load_file(f)

  d["rule-providers"] ||= {}
  d["rule-providers"]["Zscaler"] = {
    "type" => "file",
    "behavior" => "classical",
    "path" => "./rule_provider/Zscaler.yaml"
  }
  d["rule-providers"].delete("ZscalerDomains")

  d["rules"] ||= []
  d["rules"].reject! { |r| r.to_s.include?("ZscalerDomains") }
  unless d["rules"].any? { |r| r.to_s.start_with?("RULE-SET,Zscaler,") }
    d["rules"].unshift("RULE-SET,Zscaler,手动选择,no-resolve")
  end

  File.open(f, "w") { |fh| YAML.dump(d, fh) }
rescue Exception => e
  STDERR.puts "zscaler-only overwrite error: #{e}"
end
' "$CONFIG_FILE" 2>>/tmp/openclash.log

exit 0
