# Reflow post paragraphs to one sentence per line: a line ends if and only if a
# sentence ends (。！？ or . ! ? in English). Only plain paragraphs are touched;
# front matter, headings, lists, quotes, tables, code, HTML and images are left as-is.
#
# Usage (from the repo root):
#   ruby scripts/sentence-lines.rb            # reformat all posts in place
#   ruby scripts/sentence-lines.rb --check    # list posts that need it; exit 1 if any
#   ruby scripts/sentence-lines.rb FILE...    # only these files

CJK = /[\p{Han}\p{Hiragana}\p{Katakana}　-〿＀-￯“”‘’《》「」『』…—]/

# A sentence ends at 。！？ (plus any closing quotes/brackets) followed by more text,
# or at . ! ? followed by a space and a capital letter, digit, quote or CJK character.
CJK_END = /([。！？][”’」』）》"')]*)\s*(?=\S)/
ABBREV  = /(?:\b(?:Mr|Mrs|Ms|Dr|St|Jr|Sr|vs|etc|e\.g|i\.e|a\.m|p\.m|U\.S|No|Mt|ca)|\b[A-Z])\z/
PROTECT = /\]\([^)\s]*(?:\([^)\s]*\)[^)\s]*)*\)|`[^`]*`|<[^>]*>|https?:\/\/[!-~]+/
EN_END  =/([.!?]["')\]]*)\s+(?=[A-Z0-9“"(\[]|#{CJK.source})/

def join_lines(a, b)
  a = a.rstrip
  b = b.lstrip
  return b if a.empty?
  sep = (a[-1] =~ CJK || b[0] =~ CJK) ? "" : " "
  a + sep + b
end

def split_sentences(text)
  # Never break inside link targets, inline code, HTML tags or bare URLs.
  kept = []
  text = text.gsub(PROTECT) { kept << $&; "\u0001#{kept.size - 1}\u0002" }
  text = text.gsub(CJK_END) { "#{$1}\n" }
  lines = text.split("\n").flat_map do |line|
    out = []
    rest = line
    while (m = EN_END.match(rest))
      head = rest[0...m.begin(0)]
      if head =~ ABBREV
        # Abbreviation or initial: not a sentence end. Keep scanning after it.
        out << (out.pop.to_s + rest[0...m.end(0)])
        rest = rest[m.end(0)..]
        next
      end
      out << (out.pop.to_s + head + m[1])
      out << ""
      rest = rest[m.end(0)..]
    end
    out << (out.pop.to_s + rest)
    out.reject(&:empty?)
  end
  lines.map { |l| l.gsub(/\u0001(\d+)\u0002/) { kept[$1.to_i] } }
end

def reflow(lines)
  # Hard line breaks (two trailing spaces or a trailing backslash) are kept.
  segments = [[]]
  lines.each do |l|
    segments.last << l
    segments << [] if l =~ /( {2,}|\\)\n?\z/
  end
  segments.reject(&:empty?).flat_map do |seg|
    hard = seg.last =~ /( {2,}|\\)\n?\z/ ? seg.last[/( {2,}|\\)\n?\z/].chomp : nil
    text = seg.map(&:chomp).reduce("") { |acc, l| join_lines(acc, l) }
    out = split_sentences(text.strip)
    out[-1] = out[-1] + hard if hard
    out.map { |s| s + "\n" }
  end
end

# Lines that start a Markdown construct whose line breaks matter.
def structural?(line)
  line =~ /\A {0,3}(?:[-*+] |\d+[.)] |>|\||<|```|~~~|\[[^\]]+\]:)/ || line =~ /\A( {4}|\t)/
end

def standalone?(line)
  line =~ /\A {0,3}(?:#|!\[|(?:[-*_] *){3,}\s*\z)/
end

def format(src)
  lines = src.lines
  out = []
  i = 0

  # Front matter
  if lines[0]&.chomp == "---"
    j = lines[1..].index { |l| l.chomp == "---" }
    if j
      out.concat(lines[0..j + 1])
      i = j + 2
    end
  end

  para = []
  tainted = false # inside a list/quote/table/HTML block (until a blank line)
  fence = nil
  comment = false
  flush = -> { out.concat(reflow(para)) unless para.empty?; para = [] }

  while i < lines.size
    line = lines[i]
    i += 1

    if fence
      out << line
      fence = nil if line.strip.start_with?(fence)
      next
    end
    if comment
      out << line
      comment = false if line.include?("-->")
      next
    end

    if line.strip.empty?
      flush.call
      tainted = false
      out << line
    elsif line =~ /\A\s*(```|~~~)/
      flush.call
      fence = $1
      out << line
    elsif line.include?("<!--") && !line.include?("-->")
      flush.call
      comment = true
      out << line
    elsif standalone?(line)
      flush.call
      out << line
    elsif tainted || structural?(line)
      flush.call
      tainted = true
      out << line
    else
      para << line
    end
  end
  flush.call
  out.join
end

check = ARGV.delete("--check")
files = ARGV.empty? ? Dir.glob("_posts/*.{md,markdown}").sort : ARGV
changed = files.select do |f|
  src = File.binread(f).force_encoding("UTF-8")
  dst = format(src)
  next false if src == dst
  File.binwrite(f, dst) unless check
  true
end

if changed.empty?
  puts "All posts already have one sentence per line."
elsif check
  puts "Not one sentence per line (run: ruby scripts/sentence-lines.rb):"
  changed.each { |f| puts "  #{f}" }
  exit 1
else
  puts "Reformatted:"
  changed.each { |f| puts "  #{f}" }
end
