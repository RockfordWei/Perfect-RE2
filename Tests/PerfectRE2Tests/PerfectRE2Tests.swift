import XCTest
@testable import PerfectRE2

class PerfectRE2Tests: XCTestCase {
  static var allTests = [
    ("testOption", testOption),
    ("testSimple", testSimple)
  ]
  func testSimple() {
    let match = RE2.Match(pattern: "(ciao) (hello)", 
        text: "ciao hello", matches: 3)
    print("match", match)
    XCTAssertEqual(match.count, 3)
    do {
      let re2 = try RE2("(ciao) (hello)")
      XCTAssertEqual(re2.pattern ?? "failure", "(ciao) (hello)")
      let size = re2.programSize
      print("program size:", size)
      let num = re2.numerOfCapturingGroups
      print("capturing groups number:", num)
      XCTAssertGreaterThan(size, 0)
      XCTAssertEqual(num, 2)
      let m = re2.match("ciao hello", matches: 3)
      print("match with range:", m)
      XCTAssertEqual(m.count, 3)
    }catch {
      XCTFail("\(error)")
    }
  }
  func testOption() {
    let options: Set<RE2.OptionType> = [.PosixSyntax, .Literal]
    do {
      let opt = try RE2.Option(options)
      let values = opt.value
      print("option values:", values)
      XCTAssertGreaterThan(values.count, 4)
      options.forEach { o in 
        XCTAssertTrue(values.contains(o))
      }
    }catch {
      XCTFail("\(error)")
    }
  }
}
