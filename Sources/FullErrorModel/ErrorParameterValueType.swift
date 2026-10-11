//
//  ErrorParameterValueType.swift
//  fullerror-model
//
//  Created by Victor Chernykh on 08.10.2026.
//

import Foundation

/// A typed value carried with an error for client translation.
public enum ErrorParameterValueType: Codable, Sendable, Equatable {
	case integer(Int)
	case number(Decimal)
	case string(String)
	case boolean(Bool)
	case null
	case array([ErrorParameterValueType])
	case object([String: ErrorParameterValueType])

	/// Reads one value from ordinary JSON without an enum tag.
	///
	/// - Parameter decoder: The JSON decoder.
	/// - Throws: An error when the value cannot be read.
	public init(from decoder: Decoder) throws {
		let container: SingleValueDecodingContainer = try decoder.singleValueContainer()

		if container.decodeNil() {
			self = .null
		} else if let value: Bool = try? container.decode(Bool.self) {
			self = .boolean(value)
		} else if let value: Int = try? container.decode(Int.self) {
			self = .integer(value)
		} else if let value: Decimal = try? container.decode(Decimal.self) {
			self = .number(value)
		} else if let value: String = try? container.decode(String.self) {
			self = .string(value)
		} else if let value: [ErrorParameterValueType] = try? container.decode(
			[ErrorParameterValueType].self
		) {
			self = .array(value)
		} else if let value: [String: ErrorParameterValueType] = try? container.decode(
			[String: ErrorParameterValueType].self
		) {
			self = .object(value)
		} else {
			throw DecodingError.typeMismatch(
				ErrorParameterValueType.self,
				.init(
					codingPath: decoder.codingPath,
					debugDescription: "Expected a JSON error parameter value."
				)
			)
		}
	}

	/// Writes one value as ordinary JSON without an enum tag.
	///
	/// - Parameter encoder: The JSON encoder.
	/// - Throws: An error when the value cannot be written.
	public func encode(to encoder: Encoder) throws {
		var container: SingleValueEncodingContainer = encoder.singleValueContainer()

		switch self {
		case .integer(let value):
			try container.encode(value)
		case .number(let value):
			try container.encode(value)
		case .string(let value):
			try container.encode(value)
		case .boolean(let value):
			try container.encode(value)
		case .null:
			try container.encodeNil()
		case .array(let value):
			try container.encode(value)
		case .object(let value):
			try container.encode(value)
		}
	}
}
