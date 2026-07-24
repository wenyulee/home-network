#!/bin/sh
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

LOG_TIP "Start Running Custom Overwrite Scripts..."
LOGTIME=$(echo $(date "+%Y-%m-%d %H:%M:%S"))
LOG_FILE="/tmp/openclash.log"
CONFIG_FILE="$1"

ruby -ryaml -e '
begin
  f = ARGV[0]
  d = YAML.load_file(f)
  fake = /^(Expire:|Traffic:|Sync:)/i

  d["proxies"] ||= []
  d["proxies"].reject! { |p|
    n = p["name"].to_s
    n =~ fake || n == "via-RouterA"
  }

  d["proxy-groups"] ||= []
  d["proxy-groups"].reject! { |g| g["name"] == "gmail-out" || g["name"] == "Rebrickable" || g["name"] == "Japan" }
  d["proxy-groups"].each do |g|
    next unless g["proxies"].is_a?(Array)
    g["proxies"] = g["proxies"].reject { |n| n.to_s =~ fake || n.to_s == "via-RouterA" || n.to_s == "gmail-out" }
  end

  existing = (d["proxies"] || []).map { |p| p["name"].to_s }

  load_names = lambda do |path|
    names = []
    return names unless File.file?(path)
    File.readlines(path).each do |line|
      n = line.strip
      next if n.empty? || n.start_with?("#")
      names << n
    end
    names.select { |n| existing.include?(n) }
  end

  # Rebrickable: url-test among CF-safe nodes
  rb_names = load_names.call("/etc/openclash/custom/rebrickable_nodes.txt")
  if rb_names.any?
    d["proxy-groups"].unshift({
      "name" => "Rebrickable",
      "type" => "url-test",
      "proxies" => rb_names,
      "url" => "https://rebrickable.com/api/v3/",
      "interval" => 300,
      "tolerance" => 50,
      "lazy" => true,
      "expected-status" => "200"
    })
  end

  # Japan: url-test among 🇯🇵 nodes (.jp / taigatakahashi.com)
  jp_names = load_names.call("/etc/openclash/custom/japan_nodes.txt")
  if jp_names.any?
    d["proxy-groups"].unshift({
      "name" => "Japan",
      "type" => "url-test",
      "proxies" => jp_names,
      "url" => "http://www.gstatic.com/generate_204",
      "interval" => 300,
      "tolerance" => 50,
      "lazy" => true
    })
  end

  d["dns"] ||= {}
  d["dns"]["use-hosts"] = true
  d["dns"]["nameserver"] = ["https://doh.pub/dns-query", "https://1.1.1.1/dns-query", "https://dns.alidns.com/dns-query"]
  d["dns"]["direct-nameserver"] = ["https://1.1.1.1/dns-query", "https://doh.pub/dns-query"]
  d["dns"]["nameserver-policy"] ||= {}
  d["dns"]["nameserver-policy"]["+.firstrade.com"] = ["https://1.1.1.1/dns-query"]
  d["dns"]["nameserver-policy"]["+.firstrade.net"] = ["https://1.1.1.1/dns-query"]
  d["dns"]["nameserver-policy"]["+.linkedin.com"] = ["https://1.1.1.1/dns-query"]
  d["dns"]["nameserver-policy"]["+.licdn.com"] = ["https://1.1.1.1/dns-query"]
  d["hosts"] ||= {}
  d["hosts"]["api3x.firstrade.com"] = "54.230.70.76"
  d["hosts"]["streamingx.firstrade.com"] = "18.65.14.45"
  d["hosts"]["rec.firstrade.net"] = "13.226.69.45"
  d["hosts"]["www.firstrade.com"] = "76.76.21.93"
  d["hosts"]["invest.firstrade.com"] = "54.230.70.83"
  d["hosts"]["www.linkedin.com"] = "104.18.41.41"
  d["hosts"]["linkedin.com"] = "130.211.32.14"

  d["rule-providers"] ||= {}
  d["rule-providers"]["Zscaler"] = {
    "type" => "file",
    "behavior" => "classical",
    "path" => "./rule_provider/Zscaler.yaml"
  }
  d["rule-providers"].delete("ZscalerDomains")
  d["rule-providers"].delete("MailSMTP")
  d["rule-providers"]["Mail"] = {
    "type" => "file",
    "behavior" => "classical",
    "path" => "./rule_provider/Mail.yaml"
  }
  d["rule-providers"]["Rebrickable"] = {
    "type" => "file",
    "behavior" => "classical",
    "path" => "./rule_provider/Rebrickable.yaml"
  }
  d["rule-providers"]["Japan"] = {
    "type" => "file",
    "behavior" => "classical",
    "path" => "./rule_provider/Japan.yaml"
  }
  d["rule-providers"]["AI"] = {
    "type" => "file",
    "behavior" => "classical",
    "path" => "./rule_provider/AI.yaml"
  }

  d["rules"] ||= []
  d["rules"].reject! { |r|
    s = r.to_s
    s.include?("gmail-out") || s.include?("via-RouterA") ||
      s.include?("rebrickable.com") || s.start_with?("RULE-SET,Rebrickable,") ||
      s.start_with?("RULE-SET,Japan,") || s.include?("ZscalerDomains") ||
      s.include?("DOMAIN-SUFFIX,jp,") || s.include?("taigatakahashi.com")
  }

  # OpenClash may drop custom RULE-SET→group before group exists; ensure after inject
  if rb_names.any?
    d["rules"].unshift("RULE-SET,Rebrickable,Rebrickable")
  end
  if jp_names.any?
    d["rules"].unshift("RULE-SET,Japan,Japan")
  end

  File.open(f, "w") { |fh| YAML.dump(d, fh) }
rescue StandardError => e
  STDERR.puts "overwrite error: #{e}"
end
' "$CONFIG_FILE" 2>>/tmp/openclash.log

# NOTE: always exits 0 by design so OpenClash startup never blocks on this
# script; on error above, $CONFIG_FILE is left untouched (no partial write —
# the rescue fires before File.open) and the failure is only visible in
# /tmp/openclash.log ("overwrite error: ..."). There is no automatic signal
# to the caller that fake-node stripping / DNS hardening / Rebrickable /
# Japan groups were NOT applied — check the log after subscription updates
# if 手动选择/自动选择/Rebrickable/Japan groups look wrong.
exit 0
