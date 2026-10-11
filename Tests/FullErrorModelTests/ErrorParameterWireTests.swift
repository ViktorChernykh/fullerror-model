import Foundation
import Testing
@testable import FullErrorModel

private struct LegacyWireFailure: Decodable {
	let field: String
	let code: String
	let reason: String
}

private struct LegacyWireResponse: Decodable {
	let code: String
	let reason: String
	let failures: [LegacyWireFailure]?
}

@Test("Old and new error bodies preserve optional parameter states")
func optionalErrorParameterStates() throws {
	let decoder: JSONDecoder = JSONDecoder()
	let oldBody: String = """
	{
		"code":"E","reason":"old",
		"failures":[{"field":"name","code":"F","reason":"old"}]
	}
	"""
	let nullBody: String = """
	{
		"code":"E","reason":"old","parameters":null,
		"failures":[{
			"field":"name","code":"F","reason":"old","parameters":null
		}]
	}
	"""

	let optionalBodies: [String] = [oldBody, nullBody]
	for raw in optionalBodies {
		let response: ErrorResponse = try decoder.decode(
			ErrorResponse.self,
			from: Data(raw.utf8)
		)
		#expect(response.parameters == nil)
		let failure: ValidationFailure = try #require(response.failures?.first)
		#expect(failure.parameters == nil)
	}

	let emptyBody: String = """
	{
		"code":"E","reason":"old","parameters":{},
		"failures":[{
			"field":"name","code":"F","reason":"old","parameters":{}
		}]
	}
	"""
	let empty: ErrorResponse = try decoder.decode(
		ErrorResponse.self,
		from: Data(emptyBody.utf8)
	)
	#expect(empty.parameters == [:])
	let emptyFailure: ValidationFailure = try #require(empty.failures?.first)
	#expect(emptyFailure.parameters == [:])

	let oldInitializer: ErrorResponse = ErrorResponse()
	let oldFailure: ValidationFailure = ValidationFailure(
		field: "name",
		code: "F",
		reason: "old"
	)
	#expect(oldInitializer.parameters == nil)
	#expect(oldFailure.parameters == nil)

	let encodedOld: String = String(
		decoding: try JSONEncoder().encode(oldInitializer),
		as: UTF8.self
	)
	#expect(!encodedOld.contains("parameters"))
}

@Test("All JSON parameter kinds and Unicode round trip without tags")
func errorParameterKindsRoundTrip() throws {
	let raw: String = """
	{
		"code":"E","reason":"Ошибка 🚀",
		"parameters":{
			"integer":63,"number":8.5,"string":"姓名 🚀",
			"boolean":true,"null":null,
			"array":[false,{"x":"é"}],"object":{"nested":[0]}
		},
		"failures":[{
			"field":"имя","code":"F","reason":"é",
			"parameters":{"future":{"enabled":true,"items":[1,"火",null]}}
		}]
	}
	"""
	let response: ErrorResponse = try JSONDecoder().decode(
		ErrorResponse.self,
		from: Data(raw.utf8)
	)
	let outer: [String: ErrorParameterValueType] = try #require(response.parameters)
	let fraction: Decimal = Decimal(8.5)
	#expect(outer["integer"] == .integer(63))
	#expect(outer["number"] == .number(fraction))
	#expect(outer["string"] == .string("姓名 🚀"))
	#expect(outer["boolean"] == .boolean(true))
	#expect(outer["null"] == .null)
	#expect(outer["array"] == .array([.boolean(false), .object(["x": .string("é")])]))
	#expect(outer["object"] == .object(["nested": .array([.integer(0)])]))
	let nested: ValidationFailure = try #require(response.failures?.first)
	#expect(nested.field == "имя")
	#expect(nested.parameters?["future"] == .object([
		"enabled": .boolean(true),
		"items": .array([.integer(1), .string("火"), .null])
	]))

	let encoded: Data = try JSONEncoder().encode(response)
	let decoded: ErrorResponse = try JSONDecoder().decode(ErrorResponse.self, from: encoded)
	#expect(decoded.parameters == response.parameters)
	#expect(decoded.failures?.first?.parameters == nested.parameters)
	#expect(decoded.reason == "Ошибка 🚀")

	let legacy: LegacyWireResponse = try JSONDecoder().decode(
		LegacyWireResponse.self,
		from: encoded
	)
	#expect(legacy.code == "E")
	#expect(legacy.reason == "Ошибка 🚀")
	#expect(legacy.failures?.first?.field == "имя")
	#expect(legacy.failures?.first?.code == "F")
	#expect(legacy.failures?.first?.reason == "é")
}

@Test("Wrong known value kinds stay typed data, nonobject parameters fail")
func parameterEnvelopeKindBoundary() throws {
	let decoder: JSONDecoder = JSONDecoder()
	let raw: String = """
	{
		"code":"E","reason":"old","parameters":{"minimum":"8"},
		"failures":[{
			"field":"a","code":"F","reason":"old",
			"parameters":{
				"minimum":true,"maximum":null,
				"other":[1,8.5,{"ok":false}]
			}
		}]
	}
	"""
	let response: ErrorResponse = try decoder.decode(
		ErrorResponse.self,
		from: Data(raw.utf8)
	)
	let fraction: Decimal = Decimal(8.5)
	#expect(response.parameters?["minimum"] == .string("8"))
	let failure: ValidationFailure = try #require(response.failures?.first)
	#expect(failure.parameters?["minimum"] == .boolean(true))
	#expect(failure.parameters?["maximum"] == .null)
	#expect(failure.parameters?["other"] == .array([
		.integer(1),
		.number(fraction),
		.object(["ok": .boolean(false)])
	]))

	let badOuter: String = """
	{"code":"E","reason":"old","parameters":[1]}
	"""
	let badNested: String = """
	{"code":"E","reason":"old","failures":[{"field":"a","code":"F","reason":"old","parameters":7}]}
	"""
	#expect(throws: DecodingError.self) {
		try decoder.decode(ErrorResponse.self, from: Data(badOuter.utf8))
	}
	#expect(throws: DecodingError.self) {
		try decoder.decode(ErrorResponse.self, from: Data(badNested.utf8))
	}
}

@Test("Representable long fractional JSON number keeps its Decimal value")
func longFractionKeepsPrecision() throws {
	let locale: Locale = Locale(identifier: "en_US_POSIX")
	let expected: Decimal = try #require(Decimal(
		string: "1.234567890123456789",
		locale: locale
	))
	let raw: String = """
	{
		"code":"E","reason":"old",
		"parameters":{"future":1.234567890123456789}
	}
	"""
	let response: ErrorResponse = try JSONDecoder().decode(
		ErrorResponse.self,
		from: Data(raw.utf8)
	)
	#expect(response.parameters?["future"] == .number(expected))

	let encoded: Data = try JSONEncoder().encode(response)
	let decoded: ErrorResponse = try JSONDecoder().decode(
		ErrorResponse.self,
		from: encoded
	)
	#expect(decoded.parameters?["future"] == .number(expected))
}

@Test("Integral Decimal number decodes canonically as Int")
func integralDecimalCanonicalCase() throws {
	let original: ErrorResponse = ErrorResponse(
		code: "E",
		reason: "old",
		parameters: ["count": .number(Decimal(8))]
	)
	let encoded: Data = try JSONEncoder().encode(original)
	let decoded: ErrorResponse = try JSONDecoder().decode(
		ErrorResponse.self,
		from: encoded
	)
	#expect(decoded.parameters?["count"] == .integer(8))
}

@Test("Unrepresentable nested number and truncated JSON reject the envelope")
func malformedNestedParameterRejectsEnvelope() {
	let decoder: JSONDecoder = JSONDecoder()
	let unrepresentable: String = """
	{
		"code":"E","reason":"old",
		"parameters":{"future":[{"next":{"value":1e400}}]}
	}
	"""
	let truncated: String = """
	{"code":"E","reason":"old","parameters":{"future":[{"value":1}
	"""

	#expect(throws: DecodingError.self) {
		try decoder.decode(ErrorResponse.self, from: Data(unrepresentable.utf8))
	}
	#expect(throws: DecodingError.self) {
		try decoder.decode(ErrorResponse.self, from: Data(truncated.utf8))
	}
}

@Test("Encoded nil omits parameter keys and explicit empty values write objects")
func encodedParameterObjectShape() throws {
	let oldFailure: ValidationFailure = ValidationFailure(
		field: "name",
		code: "F",
		reason: "old"
	)
	let absent: ErrorResponse = ErrorResponse(
		code: "E",
		reason: "old",
		failures: [oldFailure]
	)
	let absentData: Data = try JSONEncoder().encode(absent)
	let absentObject: [String: Any] = try #require(
		JSONSerialization.jsonObject(with: absentData) as? [String: Any]
	)
	let absentFailures: [[String: Any]] = try #require(
		absentObject["failures"] as? [[String: Any]]
	)
	try #require(absentFailures.count == 1)
	#expect(absentObject["parameters"] == nil)
	#expect(absentFailures[0]["parameters"] == nil)

	let emptyFailure: ValidationFailure = ValidationFailure(
		field: "name",
		code: "F",
		reason: "old",
		parameters: [:]
	)
	let empty: ErrorResponse = ErrorResponse(
		code: "E",
		reason: "old",
		failures: [emptyFailure],
		parameters: [:]
	)
	let emptyData: Data = try JSONEncoder().encode(empty)
	let emptyObject: [String: Any] = try #require(
		JSONSerialization.jsonObject(with: emptyData) as? [String: Any]
	)
	let emptyOuter: [String: Any] = try #require(
		emptyObject["parameters"] as? [String: Any]
	)
	let emptyFailures: [[String: Any]] = try #require(
		emptyObject["failures"] as? [[String: Any]]
	)
	try #require(emptyFailures.count == 1)
	let emptyNested: [String: Any] = try #require(
		emptyFailures[0]["parameters"] as? [String: Any]
	)
	#expect(emptyOuter.isEmpty)
	#expect(emptyNested.isEmpty)
}
