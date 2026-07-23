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
  d["proxies"].reject! { |p| p["name"].to_s =~ fake || p["name"] == "via-RouterA" }
  d["proxies"].unshift({
    "name" => "via-RouterA",
    "type" => "socks5",
    "server" => "192.168.50.1",
    "port" => 7890,
    "username" => "routerb",
    "password" => "L7uC9mQ4xV2nP8sK",
    "udp" => false
  })

  d["proxy-groups"] ||= []
  d["proxy-groups"].reject! { |g| g["name"] == "gmail-out" }
  d["proxy-groups"].each do |g|
    next unless g["proxies"].is_a?(Array)
    g["proxies"] = g["proxies"].reject { |n| n.to_s =~ fake }
  end
  d["proxy-groups"].unshift({
    "name" => "gmail-out",
    "type" => "fallback",
    "proxies" => ["via-RouterA", "DIRECT"],
    "url" => "http://cp.cloudflare.com/generate_204",
    "interval" => 60,
    "timeout" => 3,
    "lazy" => false
  })

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
  d["hosts"]["www.firstrade.com"] = "76.76.21.61"
  d["hosts"]["invest.firstrade.com"] = "54.230.70.83"
  d["hosts"]["www.linkedin.com"] = "104.18.41.41"
  d["hosts"]["linkedin.com"] = "130.211.32.14"

  d["rules"] ||= []
  d["rules"].reject! { |r|
    s = r.to_s
    s.include?("smtp.gmail.com") || s.include?("firstrade.com") || s.include?("firstrade.net") || (s.include?("gmail-out") && s.include?("IP-CIDR"))
  }
  # Firstrade (proxy) + Gmail SMTP live here; LinkedIn / other mail / Rebrickable → openclash_custom_rules.list
  [
    "DOMAIN-SUFFIX,firstrade.com,手动选择",
    "DOMAIN-SUFFIX,firstrade.net,手动选择",
    "RULE-SET,AppleMedia,手动选择",
    "DOMAIN,smtp.gmail.com,gmail-out",
    "AND,((NETWORK,TCP),(DST-PORT,587),(IP-CIDR,74.125.0.0/16)),gmail-out",
    "AND,((NETWORK,TCP),(DST-PORT,465),(IP-CIDR,74.125.0.0/16)),gmail-out",
    "AND,((NETWORK,TCP),(DST-PORT,587),(IP-CIDR,142.250.0.0/15)),gmail-out",
    "AND,((NETWORK,TCP),(DST-PORT,465),(IP-CIDR,142.250.0.0/15)),gmail-out",
    "AND,((NETWORK,TCP),(DST-PORT,587),(IP-CIDR,173.194.0.0/16)),gmail-out",
    "AND,((NETWORK,TCP),(DST-PORT,465),(IP-CIDR,173.194.0.0/16)),gmail-out",
    "AND,((NETWORK,TCP),(DST-PORT,587),(IP-CIDR,209.85.128.0/17)),gmail-out",
    "AND,((NETWORK,TCP),(DST-PORT,465),(IP-CIDR,209.85.128.0/17)),gmail-out"
  ].reverse.each { |r| d["rules"].unshift(r) }

  File.open(f, "w") { |fh| YAML.dump(d, fh) }
rescue Exception => e
  STDERR.puts "gmail-relay/fake-strip error: #{e}"
end
' "$CONFIG_FILE" 2>>/tmp/openclash.log

exit 0
