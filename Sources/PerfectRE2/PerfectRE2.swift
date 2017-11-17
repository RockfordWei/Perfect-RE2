import re2api

public class RE2 {
  public func match(_ text: String, anchor: Anchor = .Unanchored, 
      range: Range<Int>? = nil, matches: Int = 1) -> [(String, Range<Int>)] {
    let r: Range<Int>
    if let rng = range {
      r = rng
    } else {
      r = 0 ..< text.count
    }
    guard matches > 0 else {
      return []
    }
    let match = UnsafeMutablePointer<cre2_string_t>.allocate(capacity: matches)
    let ranges = UnsafeMutablePointer<cre2_range_t>.allocate(capacity: matches)
    defer { 
      match.deallocate(capacity: matches) 
      ranges.deallocate(capacity: matches)
    }
    guard 0 != cre2_match_ex(ref, text, Int32(text.count), 
      Int32(r.lowerBound), Int32(r.upperBound), 
      cre2_anchor_t(rawValue: anchor.rawValue), match, ranges, Int32(matches)),
      let copy = cre2_strings_duplicate(match, Int32(matches)) 
    else {
      return []
    }
    var results: [(String, Range<Int>)] = []
    for i in 0..<matches {
      let m = copy.advanced(by: i).pointee
      let s = String(cString: m.data)
      let n = ranges.advanced(by: i).pointee
      results.append((s, n.start ..< n.past))
    }
    cre2_strings_free(copy, Int32(matches));
    return results
  }

  public static func Match(pattern: String, text: String, matches: Int) -> [String] {
    var results: [String] = []
    guard matches > 0 else {
       return results
    }
    let match = UnsafeMutablePointer<cre2_string_t>.allocate(capacity: matches)
    defer { match.deallocate(capacity: matches) }
    let retval = cre2_easy_match(pattern, Int32(pattern.count), 
      text, Int32(text.count), match, Int32(matches))
    guard retval == 1, let copy = cre2_strings_duplicate(match, Int32(matches))
    else {
      return results
    }
    for i in 0..<matches {
      let m = copy.advanced(by: i).pointee
      let s = String(cString: m.data)
      results.append(s)
    }
    cre2_strings_free(copy, Int32(matches));
    return results
  }
  internal let ref: UnsafeMutableRawPointer
  public init(_ pattern: String, options: Option? = nil) throws {
    guard let reference = cre2_new(pattern, Int32(pattern.count), options?.ref) 
    else {
      throw Exception.Unknown
    }
    let errcode = cre2_error_code(reference)
    let erc = cre2_error_code_t(rawValue: UInt32(errcode))
    switch erc {
      case CRE2_ERROR_INTERNAL: throw Exception.Internal
      case CRE2_ERROR_BAD_ESCAPE: throw Exception.BadEscape
      case CRE2_ERROR_BAD_CHAR_CLASS: throw Exception.BadCharClass
      case CRE2_ERROR_BAD_CHAR_RANGE: throw Exception.BadCharRange
      case CRE2_ERROR_MISSING_BRACKET: throw Exception.MissingBracket
      case CRE2_ERROR_MISSING_PAREN: throw Exception.MissingParen
      case CRE2_ERROR_TRAILING_BACKSLASH: throw Exception.TrailingBackSlach
      case CRE2_ERROR_REPEAT_ARGUMENT: throw Exception.RepeatArgument
      case CRE2_ERROR_REPEAT_SIZE: throw Exception.RepeatSize
      case CRE2_ERROR_REPEAT_OP: throw Exception.RepeatOp
      case CRE2_ERROR_BAD_PERL_OP: throw Exception.BadPerlOp
      case CRE2_ERROR_BAD_UTF8: throw Exception.BadUTF8
      case CRE2_ERROR_BAD_NAMED_CAPTURE: throw Exception.BadNamedCapture
      case CRE2_ERROR_PATTERN_TOO_LARGE: throw Exception.PatternTooLarge
      case CRE2_NO_ERROR: 
        ref = reference
        return 
      default:
        throw Exception.InvalidErrorCode
    }
  }
  deinit {
    cre2_delete(ref)
  }
  public var pattern: String? {
    guard let pat = cre2_pattern(ref) else {
      return ""
    }
    return String(validatingUTF8: pat)
  }
  public var programSize: Int {
    return Int(cre2_program_size(ref))
  }
  public var numerOfCapturingGroups: Int {
    return Int(cre2_num_capturing_groups(ref))
  }
  public enum Anchor: UInt32 {
    case Unanchored = 1
    case Start = 2
    case Both = 3
  }
  public enum Encodings: Int32 {
    case Unknown = 0
    case UTF8 = 1
    case Latin1 = 2
  }
  public enum OptionType: Hashable {
    case PosixSyntax, LongestMatch, LogErrors, Literal, 
      NeverNL, DotNL, NeverCapture, CaseSensitive, PerlClasses,
      WordBoundary, Online, MaxMEM(Int64), Encoding(Encodings)
    public var hashValue: Int {
      switch self {
      case .PosixSyntax: return 0x01
      case .LongestMatch: return 0x02
      case .LogErrors: return 0x03
      case .Literal: return 0x04
      case .NeverNL: return 0x05
      case .DotNL: return 0x06
      case .NeverCapture: return 0x07
      case .CaseSensitive: return 0x08
      case .PerlClasses: return 0x09
      case .WordBoundary: return 0x0A
      case .Online: return 0x0B
      case .MaxMEM: return 0x0C
      case .Encoding: return 0x0D
      }
    }
    public static func == (lhs: OptionType, rhs: OptionType) -> Bool {
      return lhs.hashValue == rhs.hashValue
    }
  }
  public enum Exception: Error {
    case InvalidOption, Internal, BadEscape, BadCharClass, BadCharRange,
      MissingBracket, MissingParen, TrailingBackSlach, RepeatArgument,
      RepeatSize, RepeatOp, BadPerlOp, BadUTF8, BadNamedCapture, 
      PatternTooLarge, Unknown, InvalidErrorCode
  }
  public class Option {
    internal let ref: UnsafeMutableRawPointer
    public var value: Set<OptionType> {
      var options: Set<OptionType> = []
      if 0 != cre2_opt_posix_syntax(ref) {
        options.insert(OptionType.PosixSyntax)
      }
      if 0 != cre2_opt_longest_match(ref) {
        options.insert(OptionType.LongestMatch)
      }
      if 0 != cre2_opt_log_errors(ref) {
        options.insert(OptionType.LogErrors)
      }
      if 0 != cre2_opt_literal(ref) {
        options.insert(OptionType.Literal)
      }
      if 0 != cre2_opt_never_nl(ref) {
        options.insert(OptionType.NeverNL)
      }
      if 0 != cre2_opt_dot_nl(ref) {
        options.insert(OptionType.DotNL)
      }
      if 0 != cre2_opt_never_capture(ref) {
        options.insert(OptionType.NeverCapture)
      }
      if 0 != cre2_opt_case_sensitive(ref) {
        options.insert(OptionType.CaseSensitive)
      }
      if 0 != cre2_opt_perl_classes(ref) {
        options.insert(OptionType.PerlClasses)
      }
      if 0 != cre2_opt_word_boundary(ref) {
        options.insert(OptionType.WordBoundary)
      }
      if 0 != cre2_opt_one_line(ref) {
        options.insert(OptionType.Online)
      }
      let memsize = cre2_opt_max_mem(ref)
      options.insert(OptionType.MaxMEM(memsize))
      let encode = cre2_opt_encoding(ref)
      if let enc = Encodings(rawValue: Int32(encode.rawValue)) {
         options.insert(OptionType.Encoding(enc))
      }
      return options
    }
    deinit {
      cre2_opt_delete(ref)
    }
    public init(_ options: Set<OptionType> = []) throws {
      guard let reference = cre2_opt_new() else {
        throw Exception.InvalidOption
      }
      ref = reference
      options.forEach { opt in 
        switch(opt) {
        case .PosixSyntax:
          cre2_opt_set_posix_syntax(ref, 1)
          break
        case .LongestMatch:
          cre2_opt_set_longest_match(ref, 1)
          break
        case .LogErrors:
          cre2_opt_set_log_errors(ref, 1)
          break
        case .Literal:
          cre2_opt_set_literal(ref, 1)
          break
        case .NeverNL:
          cre2_opt_set_never_nl(ref, 1)
          break
        case .DotNL:
          cre2_opt_set_dot_nl(ref, 1)
          break
        case .NeverCapture:
          cre2_opt_set_never_capture(ref, 1)
          break
        case .CaseSensitive:
          cre2_opt_set_case_sensitive(ref, 1)
          break
        case .PerlClasses:
          cre2_opt_set_perl_classes(ref, 1)
          break
        case .WordBoundary:
          cre2_opt_set_word_boundary(ref, 1)
          break
        case .Online:
          cre2_opt_set_one_line(ref, 1)
          break
        case .MaxMEM(let memsize):
          cre2_opt_set_max_mem(ref, memsize)
          break
        case .Encoding(let encoding):
          cre2_opt_set_encoding(ref, 
            cre2_encoding_t(rawValue: UInt32(encoding.rawValue)))
          break
        }
      }
    } 
  }
}