import SourceKittenFramework

extension SourceKittenDictionary {
    func classes(overrides: [String]) -> [SourceKittenDictionary] {
        return substructure.filter {
            $0.declarationKind == .class && $0.inheritedTypes.contains {
                overrides.contains($0)
            }
        }
    }

    var allStoredProperties: [SourceKittenDictionary] {
        return substructure.filter {
            $0.declarationKind == .varInstance && $0.bodyLength == nil
        }
    }

    func methods(names: [String], declarationKinds: [SwiftDeclarationKind]) -> [SourceKittenDictionary] {
        return substructure.filter {
            guard let name = $0.name, let kind = $0.declarationKind else { return false }
            return declarationKinds.contains(kind) && names.contains(name)
        }
    }

    func method(_ name: String) -> SourceKittenDictionary? {
        return substructure.first {
            $0.declarationKind == .functionMethodInstance && $0.name == name
        }
    }

    func classMethod(_ name: String) -> SourceKittenDictionary? {
        return substructure.first {
            $0.declarationKind == .functionMethodClass && $0.name == name
        }
    }

    func call(_ call: String) -> SourceKittenDictionary? {
        return substructure.first {
            $0.expressionKind == .call && $0.name == call
        }
    }

    var superCallName: String? {
        return name?.split(separator: "(").first.flatMap { "super.\($0)" }
    }
}
