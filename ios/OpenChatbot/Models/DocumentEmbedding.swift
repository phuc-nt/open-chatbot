import Foundation
import CoreData

// MARK: - Document Embedding Model
@objc(DocumentEmbedding)
public class DocumentEmbedding: NSManagedObject, Identifiable {
    
}

// MARK: - Core Data Properties
extension DocumentEmbedding {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DocumentEmbedding> {
        return NSFetchRequest<DocumentEmbedding>(entityName: "DocumentEmbedding")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var documentID: String
    @NSManaged public var chunkText: String
    @NSManaged public var chunkIndex: Int32
    @NSManaged public var embeddingVector: Data // Vector data for iOS 17+ Core Data Vector Search
    @NSManaged public var embeddingDimension: Int32
    @NSManaged public var language: String?
    @NSManaged public var relevanceScore: Float
    @NSManaged public var createdAt: Date
    @NSManaged public var metadata: Data? // JSON metadata for chunk
    
    // Note: Relationship with DocumentModel will be set up in Core Data model file
}

// MARK: - Convenience Methods
extension DocumentEmbedding {
    
    /// Convert embedding vector data to Float array
    var embeddingArray: [Float] {
        get {
            let floatCount = embeddingVector.count / MemoryLayout<Float>.size
            return embeddingVector.withUnsafeBytes { bytes in
                let floatBuffer = bytes.bindMemory(to: Float.self)
                return Array(floatBuffer)
            }
        }
        set {
            embeddingVector = Data(bytes: newValue, count: newValue.count * MemoryLayout<Float>.size)
            embeddingDimension = Int32(newValue.count)
        }
    }
    
    /// Get metadata as dictionary
    var metadataDict: [String: Any] {
        get {
            guard let metadata = metadata,
                  let dict = try? JSONSerialization.jsonObject(with: metadata) as? [String: Any] else {
                return [:]
            }
            return dict
        }
        set {
            guard let data = try? JSONSerialization.data(withJSONObject: newValue) else {
                metadata = nil
                return
            }
            metadata = data
        }
    }
    
    /// Calculate cosine similarity with another embedding
    func cosineSimilarity(with other: DocumentEmbedding) -> Float {
        let thisVector = self.embeddingArray
        let otherVector = other.embeddingArray
        
        guard thisVector.count == otherVector.count else { return 0.0 }
        
        let dotProduct = zip(thisVector, otherVector).map(*).reduce(0, +)
        let magnitudeA = sqrt(thisVector.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(otherVector.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
}

// MARK: - Static Methods
extension DocumentEmbedding {
    
    /// Create new embedding in context
    static func create(
        in context: NSManagedObjectContext,
        documentID: String,
        chunkText: String,
        chunkIndex: Int32,
        embedding: [Float],
        language: String? = nil,
        metadata: [String: Any] = [:]
    ) -> DocumentEmbedding {
        let embeddingObject = DocumentEmbedding(context: context)
        embeddingObject.id = UUID()
        embeddingObject.documentID = documentID
        embeddingObject.chunkText = chunkText
        embeddingObject.chunkIndex = chunkIndex
        embeddingObject.embeddingArray = embedding
        embeddingObject.language = language
        embeddingObject.relevanceScore = 0.0
        embeddingObject.createdAt = Date()
        embeddingObject.metadataDict = metadata
        
        return embeddingObject
    }
} 