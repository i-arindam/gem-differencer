# require 'rubygems'

gems = %x(gem list)
gems_array = gems.split("\n")

present_gems = gems_array.inject({}) do |h, g|
  gem_name = g.split(" ")[0]
  gem_version = g.split(" ")[1]
  version = gem_version.gsub(",", "").gsub("(", "").gsub(")", "")
  h[gem_name] = version
  h
end

truth_of_gems = {}
ith = 1
total = present_gems.size
present_gems.each do |name, version|
  puts "\n\nProcessing for '#{name}' ...\n\n"

  gem_head = %x[ gem list -ra ^#{name}$ ]
  opening_bracket = gem_head.index("(")
  closing_bracket = gem_head.index(")")
  laundry_versions = gem_head[opening_bracket + 1 .. closing_bracket - 1]
  versions = laundry_versions.split(",")
  versions.each { |v| v.strip! }
  head = versions[0]
  present_version_index = gem_head.index(version)
  delta_string = gem_head[opening_bracket + 1 .. present_version_index - 1]
  
  delta_versions = delta_string.split(",")
  delta_versions.each { |d| d.strip! }
  delta_versions.delete_if { |d| d.empty? }
  
  truth_of_gems[name] = {
    :current => version,
    :head => head,
    :delta => delta_versions
  }
  puts "Done for '#{name}'. #{ith} of #{total}"
  ith += 1
end

puts "\n\nAll processing done. Writing to output \n\n"
f = File.open("truth.txt", "wb")
f.puts(truth_of_gems.inspect)
f.close

f = File.open("truth.html", "wb")
f.puts("<html>\n<head>\n<title>Gem differences</title>\n</head>\n<body>\n")
f.puts("<table border='1'>\n")
f.puts("<tr>\n")
f.puts("<th>Name</th>\n<th>Present</th>\n<th>Remote Head</th>\n<th>Status</th>\n<th>Delta versions</th>\n<th>Away by</th>")
f.puts("</tr>\n")
truth_of_gems.each do |name, stuff|
  status, num_delta, away = if stuff[:delta].empty?
    ["OK", 0, 0]
  else
    ["LAGGING", stuff[:delta], stuff[:delta].length]
  end
  f.puts("<tr>\n")
  f.puts("<td><a href='http://rubygems.org/gems/#{name}' alt='Rubygems page'>#{name}</a></td>\n<td>#{stuff[:current]}</td>\n<td>#{stuff[:head]}</td>\n<td>#{status}</td>\n<td>#{num_delta}</td>\n<td>#{away}</td>")
  f.puts("</tr>\n")
end
f.puts("</table>\n</body>\n</html>")
f.close

puts "\n\n\nDONE.... Output files are truth.txt - Text format, in ruby object style and truth.html - HTML table format. The html is a little more beautiful\n\n\n"
