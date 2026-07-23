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
  d["proxy-groups"].reject! { |g| g["name"] == "gmail-out" || g["name"] == "Rebrickable" }
  d["proxy-groups"].each do |g|
    next unless g["proxies"].is_a?(Array)
    g["proxies"] = g["proxies"].reject { |n| n.to_s =~ fake || n.to_s == "via-RouterA" || n.to_s == "gmail-out" }
  end

  # Rebrickable: url-test among nodes that pass CF (see rebrickable_nodes.txt)
  rb_file = "/etc/openclash/custom/rebrickable_nodes.txt"
  rb_names = []
  if File.file?(rb_file)
    File.readlines(rb_file).each do |line|
      n = line.strip
      next if n.empty? || n.start_with?("#")
      rb_names << n
    end
  end
  existing = (d["proxies"] || []).map { |p| p["name"].to_s }
  rb_names.select! { |n| existing.include?(n) }
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
  d["rule-providers"]["MailSMTP"] = {
    "type" => "file",
    "behavior" => "classical",
    "path" => "./rule_provider/MailSMTP.yaml"
  }
  d["rule-providers"]["Rebrickable"] = {
    "type" => "file",
    "behavior" => "classical",
    "path" => "./rule_provider/Rebrickable.yaml"
  }

  d["rules"] ||= []
  d["rules"].reject! { |r|
    s = r.to_s
    s.include?("gmail-out") || s.include?("via-RouterA") ||
      s.include?("rebrickable.com") || s.start_with?("RULE-SET,Rebrickable,") ||
      s.include?("ZscalerDomains")
  }

  # OpenClash may drop custom RULE-SET→group before group exists; ensure after inject
  if rb_names.any?
    d["rules"].unshift("RULE-SET,Rebrickable,Rebrickable")
  end

  File.open(f, "w") { |fh| YAML.dump(d, fh) }
rescue Exception => e
  STDERR.puts "overwrite error: #{e}"
end
' "$CONFIG_FILE" 2>>/tmp/openclash.log

exit 0
