//
//  FinancialHealthInsight.swift
//  Norma
//
//  Created by Claude on 5/9/25.
//

import Foundation

struct FinancialHealthInsight: Identifiable, Codable {
    var id: String?
    let userId: String
    var score: Int
    var trend: Trend
    let psychologicalBarriers: [String]
    let assessmentData: AssessmentData?
    var createdAt: String?
    var updatedAt: String?
    
    enum Trend: String, Codable, CaseIterable {
        case improving
        case declining
        case stable
    }
    
    struct AssessmentData: Codable {
        let totalQuestions: Int
        let questionsAnswered: Int
        let conversationLength: Int
        let dataQualityScore: Double
        let lastAssessmentDate: String?
        
        enum CodingKeys: String, CodingKey {
            case totalQuestions = "total_questions"
            case questionsAnswered = "questions_answered"
            case conversationLength = "conversation_length"
            case dataQualityScore = "data_quality_score"
            case lastAssessmentDate = "last_assessment_date"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case score
        case trend
        case psychologicalBarriers = "psychological_barriers"
        case assessmentData = "assessment_data"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}