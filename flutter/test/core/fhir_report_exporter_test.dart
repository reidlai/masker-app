import 'package:flutter_test/flutter_test.dart';

class MockFHIRReportExporter {
  Map<String, dynamic> generateSignedFhirJson({
    required String patientId,
    required double ahiScore,
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
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "93832-4",
            "display": "Apnea Hypopnea Index [Events/hour]"
          }
        ]
      },
      "subject": {"reference": "Patient/$patientId"},
      "effectivePeriod": {
        "start": "2026-08-31T22:30:00Z",
        "end": "2026-09-01T06:15:00Z"
      },
      "valueQuantity": {
        "value": ahiScore,
        "unit": "events/hour",
        "system": "http://unitsofmeasure.org",
        "code": "{events}/h"
      },
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
        ahiScore: 3.2,
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
        ahiScore: 3.2,
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
  });
}
