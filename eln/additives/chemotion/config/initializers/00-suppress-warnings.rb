# Suppress deprecation warnings (e.g. stupid `URI.escape is obsolete` from paperclip)
Warning[:deprecated] = false if Warning.respond_to?(:[]=)

# Suppress warnings for already initialized constants
module Warning
  def self.warn(msg)
    return if msg =~ /already initialized constant/
    super
  end
end
