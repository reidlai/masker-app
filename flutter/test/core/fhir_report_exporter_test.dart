import 'package:flutter_test/flutter_test.dart';
import 'package:masker_app/core/constants/apnea_copy.dart';

const String _apneaOnlyCaveat = kApneaOnlyCaveat;

class MockFHIRReportExporter {
  Map<String, dynamic> generateSignedFhirJson({
    required String patientId,
    required double apneaIndexScore,
    required int durationSeconds,
    required int apneaEventsCount,
    required int safetyTapsCount,
  }) {
    return {
      "resourceType": "Observation",
      "id": "fhir-obs-2026-09-01-001",
      "status": "final",
      "category": [
        {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/observation-category",
              "code": "sleep-monitoring",
              "display": "Sleep Monitoring"
            }
          ]
        }
      ],
      "code": {
        "text": "Apnea Index (apnea events per hour, apnea-only)"
      },
      "subject": {"reference": "Patient/$patientId"},
      "effectivePeriod": {
        "start": "2026-08-31T22:30:00Z",
        "end": "2026-09-01T06:15:00Z"
      },
      "valueQuantity": {
        "value": apneaIndexScore,
        "unit": "events/hour",
        "system": "http://unitsofmeasure.org",
        "code": "{events}/h"
      },
      "note": [
        {"text": _apneaOnlyCaveat}
      ],
      "component": [
        {
          "code": {"text": "Total Duration Seconds"},
          "valueInteger": durationSeconds
        },
        {
          "code": {"text": "Apnea Events Count"},
          "valueInteger": apneaEventsCount
        },
        {
          "code": {"text": "Safety Taps Count"},
          "valueInteger": safetyTapsCount
        }
      ],
      "signature": {
        "type": [
          {
            "system": "urn:iso:astm:E1762-95:2013",
            "code": "1.2.840.10065.1.12.1.1",
            "display": "Author's Signature"
          }
        ],
        "when": "2026-09-01T07:00:00Z",
        "sigFormat": "application/jose",
        "data": "eyJhbGciOiJFUzI1NiIsImt5ZCI6ImhpcGFhLWF0dGVzdGF0aW9uIn0..."
      }
    };
  }
}

void main() {
  group('MockFHIRReportExporter Unit Tests (Serverless Mock)', () {
    late MockFHIRReportExporter exporter;

    setUp(() {
      exporter = MockFHIRReportExporter();
    });

    test('generateSignedFhirJson produces valid FHIR Observation payload', () {
      final Map<String, dynamic> fhirJson = exporter.generateSignedFhirJson(
        patientId: "david-48-persona-a",
        apneaIndexScore: 3.2,
        durationSeconds: 27900,
        apneaEventsCount: 2,
        safetyTapsCount: 1,
      );

      expect(fhirJson["resourceType"], equals("Observation"));
      expect(fhirJson["status"], equals("final"));
      expect(fhirJson["subject"]["reference"], equals("Patient/david-48-persona-a"));
      expect(fhirJson["valueQuantity"]["value"], equals(3.2));
      expect(fhirJson["signature"]["sigFormat"], equals("application/jose"));
    });

    test('FHIR report components include sleep duration and event counts', () {
      final Map<String, dynamic> fhirJson = exporter.generateSignedFhirJson(
        patientId: "david-48-persona-a",
        apneaIndexScore: 3.2,
        durationSeconds: 27900,
        apneaEventsCount: 2,
        safetyTapsCount: 1,
      );

      final List components = fhirJson["component"];
      expect(components.length, equals(3));
      expect(components[0]["valueInteger"], equals(27900));
      expect(components[1]["valueInteger"], equals(2));
      expect(components[2]["valueInteger"], equals(1));
    });

    test('code describes an apnea-only index and never references Hypopnea', () {
      final Map<String, dynamic> fhirJson = exporter.generateSignedFhirJson(
        patientId: "david-48-persona-a",
        apneaIndexScore: 3.2,
        durationSeconds: 27900,
        apneaEventsCount: 2,
        safetyTapsCount: 1,
      );

      final String codeText = fhirJson["code"]["text"] as String;
      expect(codeText.toLowerCase(), contains("apnea"));
      expect(codeText.toLowerCase(), isNot(contains("hypopnea")));
      expect(fhirJson["code"].containsKey("coding"), isFalse);
    });

    test('an Observation.note carries the canonical apnea-only caveat', () {
      final Map<String, dynamic> fhirJson = exporter.generateSignedFhirJson(
        patientId: "david-48-persona-a",
        apneaIndexScore: 3.2,
        durationSeconds: 27900,
        apneaEventsCount: 2,
        safetyTapsCount: 1,
      );

      final List notes = fhirJson["note"];
      expect(
        notes.any((n) => (n["text"] as String).contains("apnea-only screen")),
        isTrue,
      );
      expect(notes.first["text"], equals(_apneaOnlyCaveat));
    });
  });
}
